# Caelestia Shell - Agent Guidelines

This document provides guidelines for AI agents working on the Caelestia Shell project.

## Project Overview

Caelestia Shell is a Qt/QML-based desktop shell for Linux, built on top of Quickshell. It provides a modern desktop environment with widgets, notifications, system controls, and integration with Hyprland window manager.

## Build System

### CMake Build Commands
```bash
# Standard build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Install (requires sudo)
sudo cmake --install build

# Development build with debugging
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel $(nproc)
```

### Nix Build Commands
```bash
# Run directly
nix run github:caelestia-dots/shell

# Build package
nix build .#caelestia-shell

# Development shell
nix develop
```

## Linting and Formatting

### QML Files
```bash
# Format QML files
qmlformat *.qml

# Check QML formatting
qmlformat file.qml | diff -u file.qml -

# Run QML convention checker
python3 scripts/qml-lint-conventions.py
```

### C++ Files
```bash
# Format C++ files
clang-format -i *.cpp *.hpp

# Check C++ formatting
clang-format file.cpp | diff -u file.cpp -
```

### GitHub Actions
The project uses GitHub Actions for CI:
- `check-format.yml`: Checks QML and C++ formatting
- `release.yml`: Creates releases
- `update-flake-inputs.yml`: Updates Nix flake inputs

## Code Style Guidelines

### QML Style
1. **File Structure**: Follow Qt QML coding conventions (https://doc.qt.io/qt-6/qml-codingconventions.html)
2. **Section Ordering** (with blank lines between):
   - `id`
   - Property declarations
   - Signal declarations
   - JavaScript functions
   - Object properties (bindings)
   - Child objects / component definitions

3. **Imports**: Group imports logically:
   ```qml
   pragma Singleton
   
   import qs.config
   import qs.utils
   import Caelestia.Models
   import Quickshell
   import Quickshell.Io
   import QtQuick
   ```

4. **Naming**:
   - Component names: PascalCase (e.g., `FileSystemModel`)
   - Property names: camelCase (e.g., `relativePath`)
   - Signal names: camelCase (e.g., `relativePathChanged`)
   - IDs: descriptive camelCase (e.g., `wallpaperModel`)

5. **Properties**:
   - Use `readonly property` for constants
   - Use `property` for mutable values
   - Specify types explicitly (e.g., `property string path: ""`)

### C++ Style
1. **Formatting**: Use clang-format with LLVM style, 4-space indentation, 120 column limit
2. **Headers**: Use `#pragma once` not include guards
3. **Includes**: Order includes:
   - Corresponding header
   - Qt headers
   - Standard library headers
   - Third-party headers
   - Project headers

4. **Naming**:
   - Classes: PascalCase (e.g., `FileSystemEntry`)
   - Methods: camelCase (e.g., `updateRelativePath`)
   - Variables: camelCase (e.g., `parentDir`)
   - Constants: UPPER_SNAKE_CASE (e.g., `MAX_ENTRIES`)

5. **Qt Integration**:
   - Use `QML_ELEMENT` and `QML_UNCREATABLE` appropriately
   - Mark properties with `Q_PROPERTY`
   - Use `[[nodiscard]]` for pure functions
   - Use `Q_SIGNALS` and `Q_SLOTS` macros

### JavaScript (in QML)
1. **Functions**: Use JSDoc-style comments for public functions
2. **Error Handling**: Use `try/catch` for external operations
3. **Async**: Use Promises or callbacks for async operations

## Testing

### Running Tests
```bash
# Currently no formal test suite - manual testing required
# Run the shell to test changes:
caelestia shell -d
# or
qs -c caelestia
```

### Testing Guidelines
1. **Manual Testing**: Test UI changes by running the shell
2. **IPC Testing**: Test IPC commands via `caelestia shell` CLI
3. **Configuration**: Test config changes in `~/.config/caelestia/shell.json`

## Project Structure

```
caelestia/
├── assets/          # Static assets (images, shaders, scripts)
├── components/      # Reusable QML components
├── config/         # Configuration files
├── modules/        # Main UI modules (bar, sidebar, etc.)
├── services/       # Backend services (audio, network, etc.)
├── utils/          # Utility QML components
├── plugin/         # C++ Qt plugin
│   └── src/Caelestia/
│       ├── Models/ # Data models
│       └── *.cpp   # Plugin implementations
├── extras/         # Extra components
├── scripts/        # Build and lint scripts
└── nix/           # Nix package definitions
```

## Configuration

### User Configuration
- Location: `~/.config/caelestia/shell.json`
- Example config in README.md (lines 217-701)
- Never commit user config files

### Build Configuration
- CMake options in `CMakeLists.txt`
- Nix options in `flake.nix`
- Formatting rules in `.clang-format` and `.prettierrc.yaml`

## Error Handling

### QML Error Handling
1. **Property Bindings**: Use null checks before accessing properties
2. **External Calls**: Wrap in try/catch for file operations, network calls
3. **State Management**: Use `enabled` properties to disable broken components

### C++ Error Handling
1. **Exceptions**: Use Qt's exception system sparingly
2. **Null Checks**: Check pointers before dereferencing
3. **Resource Management**: Use RAII and smart pointers

## Performance Guidelines

1. **QML Performance**:
   - Use `Loader` for deferred loading
   - Avoid complex JavaScript in bindings
   - Use `ListView`/`GridView` with models for large datasets
   - Enable `cacheBuffer` for smooth scrolling

2. **C++ Performance**:
   - Use `QFuture` for async operations
   - Cache expensive computations
   - Use move semantics where possible

## Commit Guidelines

1. **Commit Messages**:
   - Format: `<type>: <description>`
   - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
   - Example: `feat: add wallpaper preview functionality`

2. **Pre-commit**:
   - Run `python3 scripts/qml-lint-conventions.py`
   - Format QML and C++ files
   - Test shell functionality

## Development Workflow

1. **Making Changes**:
   - Edit QML/C++ files
   - Run linting/formatting
   - Build with CMake or Nix
   - Test changes manually

2. **Adding Features**:
   - Add QML components to appropriate directories
   - Add C++ models if needed
   - Update configuration schema if needed
   - Document new features

3. **Debugging**:
   - Use `console.log()` in QML JavaScript
   - Use `qDebug()` in C++
   - Enable Qt debug output with `QT_LOGGING_RULES`

## Important Notes

1. **Dependencies**: See README.md for complete dependency list
2. **Platform**: Linux only, primarily Arch Linux and NixOS
3. **Window Manager**: Designed for Hyprland but compatible with others
4. **IPC**: Use `caelestia shell` CLI for IPC commands
5. **Configuration**: All user config goes in `~/.config/caelestia/`

## Resources

- [Qt QML Documentation](https://doc.qt.io/qt-6/qtqml-index.html)
- [Quickshell Documentation](https://quickshell.outfoxxed.me)
- [Hyprland Documentation](https://hyprland.org)
- [Project README](README.md) for installation and usage