#!/usr/bin/env python3
"""Checks QML files for Qt coding convention violations.

https://doc.qt.io/qt-6/qml-codingconventions.html

Required ordering within each QML object (with blank line between sections):
  1. id
  2. property declarations
  3. signal declarations
  4. JavaScript functions
  5. object properties (bindings)
  6. child objects / component definitions
"""

import re
import sys
from enum import IntEnum
from pathlib import Path

RED = "\033[0;31m"
YELLOW = "\033[0;33m"
CYAN = "\033[0;36m"
GREEN = "\033[0;32m"
MAGENTA = "\033[0;35m"
BOLD = "\033[1m"
RESET = "\033[0m"

REPO_ROOT = Path(__file__).resolve().parent.parent


class Section(IntEnum):
    ID = 0
    PROPERTY = 1
    SIGNAL = 2
    FUNCTION = 3
    BINDING = 4
    CHILD = 5
    COMPONENT_DEF = 6


SECTION_NAMES = {
    Section.ID: "id",
    Section.PROPERTY: "property declarations",
    Section.SIGNAL: "signal declarations",
    Section.FUNCTION: "functions",
    Section.BINDING: "bindings",
    Section.CHILD: "child objects",
    Section.COMPONENT_DEF: "component definitions",
}

RULE_COLOURS = {
    "missing-blank-after-id": RED,
    "section-order": YELLOW,
    "missing-section-separator": CYAN,
    "blank-after-open-brace": MAGENTA,
    "blank-before-close-brace": MAGENTA,
}

# Regexes
PROPERTY_DECL_RE = re.compile(
    r"^(?:required\s+|readonly\s+|default\s+)*property\s"
)
SIGNAL_RE = re.compile(r"^signal\s")
FUNCTION_RE = re.compile(r"^function\s")
ID_RE = re.compile(r"^id\s*:\s*[a-zA-Z_]\w*\s*$")
ENUM_RE = re.compile(r"^enum\s")
COMPONENT_DEF_RE = re.compile(r"^component\s+\w+\s*:")
COMMENT_LINE_RE = re.compile(r"^//")
BLOCK_COMMENT_START = re.compile(r"/\*")
BLOCK_COMMENT_END = re.compile(r"\*/")
BINDING_RE = re.compile(r"^[a-z][a-zA-Z0-9_.]*\s*:")
SIGNAL_HANDLER_RE = re.compile(r"^on[A-Z][a-zA-Z]*\s*:")
# Child object: starts with uppercase or is a known child-like pattern
CHILD_OBJECT_RE = re.compile(r"^[A-Z][a-zA-Z0-9_.]*\s*\{")
# Inline component: Component { ... }
INLINE_COMPONENT_RE = re.compile(r"^Component\s*\{")
# Behavior on <property> {, NumberAnimation on <property> {, etc.
BEHAVIOR_ON_RE = re.compile(r"^[A-Z]\w+\s+on\s+\w[\w.]*\s*\{")
# Attached signal handler: Component.onCompleted:, Drag.onDragStarted:, etc.
ATTACHED_HANDLER_RE = re.compile(r"^[A-Z]\w+\.on[A-Z]\w*\s*:")


class Violation:
    def __init__(self, file: str, line: int, rule: str, msg: str):
        self.file = file
        self.line = line
        self.rule = rule
        self.msg = msg

    def __str__(self):
        c = RULE_COLOURS.get(self.rule, "")
        return f"{c}[{self.rule}]{RESET} {self.file}:{self.line}: {self.msg}"


class ScopeTracker:
    """Tracks the current section and last-seen state for one indent level."""

    def __init__(self):
        self.last_section: Section | None = None
        self.last_section_line: int = 0
        self.had_blank_before_current: bool = True  # no separator needed at start


def get_indent(line: str) -> str:
    return line[: len(line) - len(line.lstrip())]


def classify_line(stripped: str) -> Section | None:
    """Classify a stripped QML line into a section category."""
    if ID_RE.match(stripped):
        return Section.ID
    if PROPERTY_DECL_RE.match(stripped):
        return Section.PROPERTY
    if SIGNAL_RE.match(stripped):
        return Section.SIGNAL
    if FUNCTION_RE.match(stripped):
        return Section.FUNCTION
    if ENUM_RE.match(stripped):
        return Section.PROPERTY  # enums go with declarations
    if COMPONENT_DEF_RE.match(stripped):
        return Section.COMPONENT_DEF
    if BEHAVIOR_ON_RE.match(stripped):
        return Section.CHILD
    if CHILD_OBJECT_RE.match(stripped):
        return Section.CHILD
    if INLINE_COMPONENT_RE.match(stripped):
        return Section.CHILD
    if BINDING_RE.match(stripped) or SIGNAL_HANDLER_RE.match(stripped):
        return Section.BINDING
    if ATTACHED_HANDLER_RE.match(stripped):
        return Section.BINDING
    return None


def check_file(filepath: Path) -> list[Violation]:
    violations = []
    rel = str(filepath.relative_to(REPO_ROOT))

    try:
        lines = filepath.read_text().splitlines()
    except (OSError, UnicodeDecodeError):
        return violations

    scopes: dict[str, ScopeTracker] = {}  # indent -> tracker
    in_block_comment = False
    func_skip_depth = 0  # brace depth for skipping function bodies only
    prev_blank: dict[str, bool] = {}  # indent -> was previous relevant line a blank?

    for i, line in enumerate(lines):
        lineno = i + 1
        stripped = line.strip()
        indent = get_indent(line)

        # Handle block comments
        if in_block_comment:
            if BLOCK_COMMENT_END.search(stripped):
                in_block_comment = False
            continue
        if BLOCK_COMMENT_START.search(stripped) and not BLOCK_COMMENT_END.search(stripped):
            in_block_comment = True
            continue

        # Track blank lines per indent
        if not stripped:
            # Check: blank line right after opening brace of a QML object
            if (i > 0 and func_skip_depth == 0 and not in_block_comment
                    and lines[i - 1].strip().endswith("{")):
                violations.append(Violation(
                    rel, lineno, "blank-after-open-brace",
                    "no blank line expected after opening brace",
                ))
            for key in prev_blank:
                prev_blank[key] = True
            continue

        # Skip line comments
        if COMMENT_LINE_RE.match(stripped):
            continue

        # Skip inside function bodies (JS code, not QML structure)
        if func_skip_depth > 0:
            func_skip_depth += stripped.count("{") - stripped.count("}")
            if func_skip_depth <= 0:
                func_skip_depth = 0
            continue

        # Closing brace: pop scope for this indent and all deeper scopes
        if stripped == "}":
            # Check: blank line right before closing brace
            if i > 0 and not lines[i - 1].strip():
                violations.append(Violation(
                    rel, lineno, "blank-before-close-brace",
                    "no blank line expected before closing brace",
                ))
            scopes.pop(indent, None)
            prev_blank.pop(indent, None)
            to_remove = [k for k in scopes if len(k) > len(indent)]
            for k in to_remove:
                del scopes[k]
                prev_blank.pop(k, None)
            continue

        section = classify_line(stripped)
        if section is None:
            continue

        # Get or create scope tracker for this indent
        if indent not in scopes:
            scopes[indent] = ScopeTracker()
            prev_blank[indent] = True  # treat start of object as having separator

        tracker = scopes[indent]
        had_blank = prev_blank.get(indent, True)

        # --- Check 1: Missing blank line after id ---
        if section == Section.ID:
            if i + 1 < len(lines):
                next_stripped = lines[i + 1].strip()
                if next_stripped and next_stripped != "}":
                    violations.append(Violation(
                        rel, lineno, "missing-blank-after-id",
                        "id should be followed by a blank line",
                    ))

        # --- Check 2: Section ordering ---
        if tracker.last_section is not None and section < tracker.last_section:
            violations.append(Violation(
                rel, lineno, "section-order",
                f"{SECTION_NAMES[section]} should appear before "
                f"{SECTION_NAMES[tracker.last_section]} "
                f"(seen at line {tracker.last_section_line})",
            ))

        # --- Check 3: Missing blank line between different sections ---
        if (tracker.last_section is not None
                and section != tracker.last_section
                and not had_blank):
            violations.append(Violation(
                rel, lineno, "missing-section-separator",
                f"blank line expected between {SECTION_NAMES[tracker.last_section]} "
                f"and {SECTION_NAMES[section]}",
            ))

        # Update tracker
        if tracker.last_section is None or section >= tracker.last_section:
            tracker.last_section = section
            tracker.last_section_line = lineno

        prev_blank[indent] = False

        # Skip function bodies (they contain JS, not QML structure)
        brace_count = stripped.count("{") - stripped.count("}")
        if brace_count > 0 and section == Section.FUNCTION:
            func_skip_depth = brace_count

        # Skip JS blocks in bindings (signal handlers, attached handlers,
        # and expression blocks like `color: { ... }`)
        if brace_count > 0 and section == Section.BINDING:
            colon_idx = stripped.index(":")
            after_colon = stripped[colon_idx + 1:].strip()
            # If content after : doesn't start with an uppercase type name,
            # it's a JS block (not an inline QML object like `contentItem: Rect {`)
            if not re.match(r"^[A-Z]", after_colon):
                func_skip_depth = brace_count

        # Child object/component opening resets deeper scopes
        if brace_count > 0 and section in (Section.CHILD, Section.COMPONENT_DEF):
            to_remove = [k for k in scopes if len(k) > len(indent)]
            for k in to_remove:
                del scopes[k]
                prev_blank.pop(k, None)

    return violations


def main():
    qml_files = sorted(
        p for p in REPO_ROOT.rglob("*.qml")
        if "build" not in p.parts
    )

    print(f"{BOLD}Checking {len(qml_files)} QML files for convention violations...{RESET}\n")

    all_violations: list[Violation] = []
    for f in qml_files:
        all_violations.extend(check_file(f))

    for v in all_violations:
        print(v)

    print()
    if all_violations:
        by_rule: dict[str, int] = {}
        for v in all_violations:
            by_rule[v.rule] = by_rule.get(v.rule, 0) + 1
        for rule, count in sorted(by_rule.items()):
            print(f"  {RULE_COLOURS.get(rule, '')}{rule}{RESET}: {count}")
        print(f"\n{BOLD}Found {len(all_violations)} violation(s).{RESET}")
        return 1
    else:
        print(f"{BOLD}No violations found.{RESET}")
        return 0


if __name__ == "__main__":
    sys.exit(main())
