# Caelestia Shell - Project Context for AI Assistant

This directory contains the configuration and QML source code for the
**Caelestia Shell**, a desktop shell built using the
[Quickshell](https://quickshell.outfoxxed.me) framework. It's part of the larger
[Caelestia dotfiles](https://github.com/caelestia-dots) ecosystem, designed
primarily for the Hyprland window manager.

## Project Type

This is a **code project**. It is a QML-based desktop shell application built
with the Quickshell framework for Linux (specifically targeting Hyprland).

## Core Technologies

- **[Quickshell](https://quickshell.outfoxxed.me):** The core framework for
  building the desktop shell. It uses QML (Qt Meta-Object Language) and C++.
- **QML (Qt Meta-Object Language):** The primary language for defining the UI
  and logic of the shell components.
- **CMake:** Build system used for installation.
- **Nix:** Supported package manager for installation and configuration.
- **Hyprland:** The target window manager, with integration via global shortcuts
  and IPC.

## Project Structure Overview

- `shell.qml`: The main entry point for the shell, importing various modules.
- `shell.json`: The primary configuration file for customizing the shell's
  appearance, behavior, and features.
- `modules/`: Contains QML files defining global behavior like shortcuts
  (`Shortcuts.qml`).
- `components/`: Reusable UI components (e.g., animations, icons, styled
  elements).
- `config/`: QML files defining the structure and types for the configuration
  options found in `shell.json`. `Config.qml` is the central singleton that
  loads `shell.json`.
- `assets/`: Likely contains static assets like images or QML files for assets
  (e.g., the bongocat and kurukuru GIFs referenced in the config).
- `services/`: Likely contains QML or other code related to interacting with
  system services (e.g., audio, network, MPRIS).
- `CMakeLists.txt`: Build/installation configuration.
- `nix/`: Nix-specific packaging and module definitions.
- `README.md`: Detailed documentation on installation, usage, configuration, and
  FAQ.

## Key Configuration

The shell is highly configurable via a JSON file located at
`~/.config/caelestia/shell.json`. The structure of this file is defined by the
QML files in the `config/` directory. Modifying this file allows users to change
fonts, colors, enable/disable features, adjust sizes, and configure behavior
without touching the source code.

## Building and Running

Refer to the `README.md` for detailed installation instructions, including AUR,
Nix, and manual methods. The core steps for a manual build involve:

1. Cloning the repository to `$XDG_CONFIG_HOME/quickshell/caelestia` (typically
   `~/.config/quickshell/caelestia`).
2. Ensuring all dependencies are installed (e.g., `quickshell-git`, `ddcutil`,
   `cava`, `material-symbols` font, etc.).
3. Using `cmake` and `ninja` to build:

   ```bash
   cd $XDG_CONFIG_HOME/quickshell/caelestia
   cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
   cmake --build build
   sudo cmake --install build
   ```

4. Starting the shell with `caelestia shell -d` or `qs -c caelestia`.

## Development Conventions

- **QML:** UI and logic are defined in `.qml` files. Components are organized
  into directories like `components/` for reusable elements and `modules/` for
  larger functional blocks.
- **Configuration:** Centralized in `shell.json` and accessed via the `Config`
  singleton QML object.
- **Dependencies:** Managed externally (e.g., system packages, AUR, Nix) rather
  than vendored.
- **Styling:** Uses custom QML components (`StyledRect`, `StyledText`, etc.) for
  consistent theming, likely controlled via the `Appearance` configuration.

## Usage (User Perspective)

Users interact with the shell primarily through:

- **Hyprland Shortcuts:** Global keyboard shortcuts for features like the
  launcher, dashboard, session menu, etc.
- **IPC Commands:** Command-line interface via `caelestia shell ...` to control
  various aspects (e.g., media playback, wallpaper setting, notification
  clearing).
- **GUI Elements:** Direct interaction with on-screen elements like the status
  bar, launcher, dashboard, notifications, and OSD.

## Key Files for Understanding the Project

1. `README.md`: Essential for understanding the project's purpose, installation,
   and usage.
2. `shell.qml`: The main application structure.
3. `shell.json`: The live configuration file.
4. `config/Config.qml` & `config/*.qml`: Define the configuration schema.
5. `modules/Shortcuts.qml`: Defines global shortcuts and IPC handlers.
6. `components/*.qml`: Reusable UI building blocks.
