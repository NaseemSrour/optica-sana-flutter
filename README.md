# OptiSana

A cross-platform Flutter application for managing an optometry practice: customer records,
glasses prescriptions, contact-lens tests, birthday reminders, and multi-language support
(English, Hebrew, Arabic).

Primary target: **Windows desktop**. Also builds for Android, iOS, macOS, Linux, and Web.

---

## Table of contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
- [Project structure](#project-structure)
- [Running](#running)
- [Building for production](#building-for-production)
- [Packaging the Windows installer](#packaging-the-windows-installer)
- [Data locations](#data-locations)
- [Localization](#localization)
- [License](#license)

---

## Features

- Customer CRUD with search and birthday-month lookup
- Glasses prescription history with numeric input masks, axis validation, quarter-step checks, and L-row focus traversal
- Contact-lens test history with solution tracking
- Configurable dropdown option lists (frame types, lens types, colors, etc.)
- Password lock on app launch (SHA-256 + salt, stored in `shared_preferences`)
- Configurable input font size (12–36)
- Auto-discovered notification sounds from `assets/sounds/`
- Backup / restore of the SQLite database
- Full RTL support for Hebrew & Arabic via `easy_localization`

---

## Tech stack

### Core SDK

| Tool         | Version           | Notes                                      |
| ------------ | ----------------- | ------------------------------------------ |
| **Flutter**  | `3.38.8` (stable) | Channel: `stable`, revision `bd7a4a6b55`   |
| **Dart**     | `3.10.7`          | Bundled with the Flutter SDK               |
| **DevTools** | `2.51.1`          | Bundled with the Flutter SDK               |

Project `environment` constraint (from `pubspec.yaml`):

```yaml
environment:
  sdk: ^3.8.1
```

### Runtime dependencies

| Package              | Version   | Purpose                                        |
| -------------------- | --------- | ---------------------------------------------- |
| `sqflite_common_ffi` | `^2.0.0`  | SQLite on desktop (Windows / macOS / Linux)    |
| `path_provider`      | `^2.1.5`  | Resolve platform-specific document directories |
| `path`               | `^1.9.1`  | Path manipulation                              |
| `intl`               | `^0.20.2` | Date / number formatting                       |
| `easy_localization`  | `^3.0.7`  | JSON-based i18n (en / he / ar)                 |
| `package_info_plus`  | `^8.1.2`  | App version / build info at runtime            |
| `audioplayers`       | `^6.0.0`  | Notification-sound playback                    |
| `shared_preferences` | `^2.3.0`  | Persist password hash, font size, sound choice |
| `crypto`             | `^3.0.3`  | SHA-256 for password hashing                   |
| `cupertino_icons`    | `^1.0.8`  | iOS-style icons                                |

### Dev dependencies

| Package         | Version  | Purpose                |
| --------------- | -------- | ---------------------- |
| `flutter_test`  | SDK      | Widget tests           |
| `flutter_lints` | `^5.0.0` | Recommended lint rules |

> Exact resolved versions (including transitive dependencies) are pinned in `pubspec.lock`.
> Commit that file — do **not** delete it.

---

## Prerequisites

### Required on every development machine

1. **Flutter SDK 3.38.x (stable)** — install via one of:
   - [Official installer](https://docs.flutter.dev/get-started/install) (recommended)
   - `choco install flutter` (Chocolatey on Windows)
   - `brew install --cask flutter` (macOS)

2. **Git** — `git --version` should succeed.

3. **An editor** — either is fine:
   - **VS Code** with the _Flutter_ and _Dart_ extensions (Microsoft publisher).
   - **Android Studio** / **IntelliJ IDEA** with the Flutter plugin.

4. Run `flutter doctor` and resolve everything relevant to your target platforms.

### Platform-specific toolchains

Install only the toolchains for the platforms you actually build for.

#### Windows desktop (primary target)

- **Windows 10 version 1809** (build 17763) or newer, x64.
- **Visual Studio 2022 Community / Pro / Enterprise** with these workloads:
  - **Desktop development with C++**
  - **Windows 10 / 11 SDK** (auto-selected by the workload above)
- **Inno Setup 6** — required only to build the installer.
  Download: <https://jrsoftware.org/isinfo.php>

#### Android

- **Android Studio** (bundles the Android SDK, platform-tools, emulator).
- **Java 17** (bundled with recent Android Studio).
- Accept SDK licenses: `flutter doctor --android-licenses`.

#### iOS / macOS

- **macOS 13** or newer.
- **Xcode 15** or newer (from the Mac App Store).
- **CocoaPods**: `sudo gem install cocoapods`.
- A valid Apple Developer account (only needed to sign / distribute).

#### Linux desktop

- `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev`.
- On Debian / Ubuntu:
  ```bash
  sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
  ```

#### Web

- Chrome or Edge (already installed on any dev machine).
- No extra setup — enabled by default in recent Flutter versions.

### Verify your setup

```powershell
flutter doctor -v
```

All relevant checkmarks must be green for your target platform(s) before proceeding.

---

## Getting started

```powershell
# 1. Clone
git clone https://github.com/<your-org>/optica-sana-flutter.git
cd optica-sana-flutter

# 2. Fetch dependencies
flutter pub get

# 3. Verify
flutter analyze
flutter test
```

---

## Project structure

```
optica-sana-flutter/
├── lib/
│   ├── main.dart                     # App entry + root MaterialApp
│   ├── db_flutter/                   # SQLite schema, models, repositories
│   ├── flutter_services/             # AppSettings, AuthService, SoundService, CustomerService
│   ├── screens/                      # All top-level screens
│   ├── widgets/                      # Reusable widgets (DropdownField, tables, masks, etc.)
│   └── themes/                       # App theme + text styles
├── assets/
│   ├── icons/ images/ sounds/
│   └── translations/                 # en.json, he.json, ar.json
├── windows/                          # Windows runner (CMake, Runner.rc, main.cpp)
├── android/  ios/  macos/  linux/  web/
├── installer/
│   ├── OptiSana.iss                  # Inno Setup script
│   └── RELEASE_GUIDE.html            # Step-by-step release guide
├── test/                             # Widget tests
├── pubspec.yaml
├── pubspec.lock                      # Pinned dependency versions
└── analysis_options.yaml
```

---

## Running

### Windows (primary)

```powershell
flutter run -d windows
```

### Other platforms

```powershell
flutter devices                 # list available targets
flutter run -d chrome           # web
flutter run -d <emulator-id>    # android
flutter run -d macos            # macOS (on a Mac)
```

Hot reload: press `r`. Hot restart: press `R`. Quit: `q`.

---

## Building for production

### Windows

```powershell
flutter clean
flutter build windows --release
```

Output: `build\windows\x64\runner\Release\` — contains `OptiSana.exe`, `flutter_windows.dll`,
all plugin DLLs, and a `data\` folder. The entire folder must be distributed together.

### Android

```powershell
flutter build appbundle --release     # for Play Store (.aab)
flutter build apk --release           # standalone .apk
```

### iOS / macOS

```bash
flutter build ios --release
flutter build macos --release
```

### Web

```powershell
flutter build web --release
```

---

## Packaging the Windows installer

The repo includes an Inno Setup script at [`installer/OptiSana.iss`](installer/OptiSana.iss).

```powershell
# 1. Build the release (if not already built)
flutter build windows --release

# 2. Compile the installer
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\OptiSana.iss
```

Output: `build\installer\OptiSana-Setup-<version>.exe` — a single, self-contained installer.

For the full step-by-step release workflow (version bumping, SmartScreen notes, upgrade
behavior, troubleshooting), open [`installer/RELEASE_GUIDE.html`](installer/RELEASE_GUIDE.html)
in your browser.

---

## Data locations

User data is stored in standard per-user locations and survives app updates and uninstalls:

| What                | Location                                                 |
| ------------------- | -------------------------------------------------------- |
| SQLite database     | `%UserProfile%\Documents\OpticaSana.db` (Windows)        |
| Preferences         | `HKCU\Software\Naseem Srour\OptiSana` (Windows Registry) |
| Notification sounds | Bundled inside `data\flutter_assets\assets\sounds\`      |

On other platforms the database lives in `path_provider.getApplicationDocumentsDirectory()`
and preferences in the platform's standard `shared_preferences` backing store.

---

## Localization

Translation files live in `assets/translations/`:

- `en.json` — English (default fallback)
- `he.json` — Hebrew (RTL)
- `ar.json` — Arabic (RTL)

To add or change a string, edit all three JSON files (same keys). A full **app restart**
is required for `easy_localization` to reload its cache — hot reload alone is not enough.

Supported locales and the fallback are registered in [`lib/main.dart`](lib/main.dart).

---

## Contributing

1. Create a feature branch: `git checkout -b feature/my-change`.
2. Keep commits focused; run `flutter analyze` and `flutter test` before pushing.
3. Match existing code style — the project uses `flutter_lints`.
4. Open a pull request against `main`.

---

## License

Proprietary — © 2026 Naseem Srour. All rights reserved.
Not open source. Do not redistribute without permission.
# optica_sana

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
