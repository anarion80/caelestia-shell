# Top Bar Migration Guide

> [!WARNING] This is AI generated. Check the diff link at the bottom for full
> change.

This document describes the changes required to migrate the Caelestia Shell bar
from the left side of the screen to the top. The migration involves significant
changes to layout, coordinate systems, and component positioning.

## Overview

The original bar was designed as a vertical sidebar on the left edge of the
screen. Moving it to the top required converting all vertical layouts to
horizontal, swapping coordinate systems, and updating positioning logic
throughout the codebase.

## File Changes Summary

**39 files changed, 1130 insertions(+), 240 deletions(-)**

### Core Bar Components

- `modules/bar/Bar.qml` - Main bar container
- `modules/bar/BarWrapper.qml` - Bar wrapper with animations
- `modules/bar/components/ActiveWindow.qml` - Active window display
- `modules/bar/components/Clock.qml` - Clock component
- `modules/bar/components/StatusIcons.qml` - Status icons
- `modules/bar/components/Tray.qml` - System tray
- `modules/bar/components/workspaces/*` - Workspace components

### Popout System

- `modules/bar/popouts/ClipWrapper.qml` - Popout positioning wrapper
- `modules/bar/popouts/Content.qml` - Popout content
- `modules/bar/popouts/Wrapper.qml` - Popout wrapper

### Configuration

- `config/BarConfig.qml` - Bar configuration
- `shell.json` - User configuration

### Drawer System

- `modules/drawers/Regions.qml` - Drawer interaction regions
- `modules/drawers/ContentWindow.qml` - Content window positioning

## Detailed Migration Steps

### 1. Layout Container Changes

**Before (Vertical):**

```qml
ColumnLayout {
    // Vertical layout
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignHCenter
}
```

**After (Horizontal):**

```qml
RowLayout {
    // Horizontal layout
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignVCenter
}
```

**Files affected:**

- `Bar.qml`: `ColumnLayout` → `RowLayout`
- `Clock.qml`: `Column` → `Row`
- Various component layouts

### 2. Coordinate System Swapping

All coordinate calculations need to swap X/Y axes:

**Before:**

```qml
function checkPopout(y: real): void {
    const ch = childAt(width / 2, y);
    const top = ch.y;
    // Vertical calculations
}
```

**After:**

```qml
function checkPopout(x: real): void {
    const ch = childAt(x, height / 2);
    const left = ch.x;
    // Horizontal calculations
}
```

**Key transformations:**

- `x` ↔ `y`
- `width` ↔ `height`
- `left`/`right` ↔ `top`/`bottom`
- `horizontalCenter` ↔ `verticalCenter`

### 3. Property Renaming

**Before:**

```qml
readonly property int vPadding: Appearance.padding.large
readonly property int clampedWidth: Math.max(Config.border.minThickness, implicitWidth)
readonly property int contentWidth: Config.bar.sizes.innerWidth + padding * 2
```

**After:**

```qml
readonly property int hPadding: Appearance.padding.large
readonly property int clampedHeight: Math.max(Config.border.minThickness, implicitHeight)
readonly property int contentHeight: Config.bar.sizes.innerHeight + padding * 2
```

### 4. Component-Specific Changes

#### ActiveWindow Component

- Changed from vertical icon+text stack to horizontal layout
- Removed text rotation transforms (no longer needed for vertical text)
- Updated `maxHeight` calculation to `maxWidth`
- Swapped `implicitWidth`/`implicitHeight` calculations

#### Clock Component

- Changed date/time from stacked to inline format
- Date format: `"ddd\nd"` → `"ddd d"`
- Time format: `"hh\nmm\nA"` → `"hh:mm A"`
- Removed separator line between date and time

#### StatusIcons Component

- Changed from vertical to horizontal layout
- Updated icon spacing and positioning

#### Tray Component

- Updated layout from vertical to horizontal
- Changed expand icon positioning logic

### 5. Popout System Rewrite

The popout system required complete repositioning logic:

**Before (vertical bar, popouts to the right):**

```qml
x: 0  // Always at bar right edge
y: calculateVerticalPosition()  // Align with hovered component
```

**After (top bar, popouts downward):**

```qml
x: calculateHorizontalPosition()  // Align with hovered component
y: 0  // Always at bar bottom edge
```

**Key changes in `ClipWrapper.qml`:**

- `offsetScale` logic: `x > 0` → `content.hasCurrent || content.isDetached`
- Swapped `implicitWidth`/`implicitHeight` calculations
- Completely rewritten positioning logic
- Changed anchors from `verticalCenter`/`left` to `horizontalCenter`/`top`

### 6. Drawer Region Updates

**Before (left bar):**

```qml
x: bar.clampedWidth + win.dragMaskPadding
y: Config.border.clampedThickness + win.dragMaskPadding
width: win.width - bar.clampedWidth - Config.border.clampedThickness - win.dragMaskPadding * 2
height: win.height - Config.border.clampedThickness * 2 - win.dragMaskPadding * 2
```

**After (top bar):**

```qml
x: Config.border.clampedThickness + win.dragMaskPadding
y: bar.clampedHeight + win.dragMaskPadding
width: win.width - Config.border.clampedThickness * 2 - win.dragMaskPadding * 2
height: win.height - bar.clampedHeight - Config.border.clampedThickness - win.dragMaskPadding * 2
```

### 7. Configuration Updates

**BarConfig.qml:**

- Added `Mail` component configuration
- Changed `sizes.innerWidth: 40` → `sizes.innerHeight: 40`

**shell.json:**

- Added mail entry to bar entries array
- Updated `innerHeight` value in sizes configuration

### 8. Mouse Wheel Behavior

**Before (vertical halves):**

```qml
if (y < screen.height / 2 && Config.bar.scrollActions.volume) {
    // Volume scroll on top half
} else if (Config.bar.scrollActions.brightness) {
    // Brightness scroll on bottom half
}
```

**After (horizontal halves):**

```qml
if (x < screen.width / 2 && Config.bar.scrollActions.volume) {
    // Volume scroll on left half
} else if (Config.bar.scrollActions.brightness) {
    // Brightness scroll on right half
}
```

### 9. New Features Added

During the migration, mail notification support was added:

- `modules/bar/components/Mail.qml` - Mail notification component
- `modules/bar/popouts/Mail.qml` - Mail popout
- `services/MailService.qml` - Mail service backend
- Configuration in `BarConfig.qml` and `shell.json`

## Testing Checklist

After migration, verify:

1. **Bar displays correctly** at top of screen
2. **All components render** in horizontal layout
3. **Popouts appear below** hovered components
4. **Mouse wheel scrolling** works on correct halves
5. **Drawer interactions** respect new bar position
6. **Animations work smoothly** for show/hide
7. **Configuration changes** apply correctly
8. **Mail notifications** (if enabled) function properly

## Common Issues and Solutions

### Issue: Popouts positioned incorrectly

**Solution:** Check `ClipWrapper.qml` positioning logic and ensure coordinate
calculations use the correct axes.

### Issue: Components overlapping

**Solution:** Verify `Layout.fillWidth` vs `Layout.fillHeight` properties and
spacing values.

### Issue: Mouse interactions not working

**Solution:** Ensure `checkPopout()` and `handleWheel()` functions use correct
coordinate parameters.

### Issue: Bar doesn't hide/show properly

**Solution:** Check `BarWrapper.qml` animation properties and `implicitHeight`
calculations.

## Reverting to Sidebar

To revert to the left sidebar configuration, reverse all the changes listed
above, particularly:

1. Change `RowLayout` back to `ColumnLayout`
2. Swap all coordinate systems back
3. Revert property renames
4. Restore vertical component layouts
5. Update popout positioning for right-side display

## References

- **Complete diff between fork and upstream**:
  [https://github.com/anarion80/caelestia-shell/compare/aa2b08dd45963dc9558de94dbff5e1615e347d02...7bafc7d9bff9bdaaffa260ce69f13dcbaad929f7](https://github.com/anarion80/caelestia-shell/compare/aa2b08dd45963dc9558de94dbff5e1615e347d02...ffa318615ded6884c1d6c7b5f5e08c9ea7d387ed)
- **Fork commit**: `7bafc7d9bff9bdaaffa260ce69f13dcbaad929f7` (latest in fork)
- **Upstream commit**: `aa2b08dd45963dc9558de94dbff5e1615e347d02` (base from
  upstream/main)
- Affected files: 39 total
- Key concepts: Layout switching, coordinate transformation, positioning logic
