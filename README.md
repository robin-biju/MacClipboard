# MacClipboard

A beautifully native, extremely lightweight menu bar clipboard manager for macOS, written in pure Swift and SwiftUI.

## 👨‍💻 Author

Designed and developed by [Robin Biju](https://robinbiju.com).

## ✨ Features

- **Blazing Fast**: Compiles directly to native Apple Silicon machine code. Consumes virtually 0% CPU while idling in the background.
- **Fuzzy Search**: Quickly find past copied items instantly using a smart fuzzy search algorithm right from the menu bar.
- **Keyboard Navigation**: Keep your hands on the keyboard! Use the `Up` and `Down` arrows to navigate your history, hit `Enter` to copy, and `Option + Delete` to instantly remove an item.
- **Privacy First (App Exclusions)**: Built-in protection for password managers (like 1Password, Keychain) using standard macOS secure pasteboard flags. You can also manually add specific apps to your exclusion list in the Settings window so their copied text is completely ignored!
- **Zero Clutter**: Runs entirely in your menu bar. No dock icon, no bloated web frameworks, just a clean, native macOS interface.

## 🚀 Building from Source

This project uses a simple shell script to compile the Swift files directly without needing Xcode bloat.

1. Clone the repository:
   ```bash
   git clone https://github.com/robin-biju/MacClipboard.git
   cd MacClipboard
   ```
2. Build the app:
   ```bash
   ./build.sh
   ```
3. Run the app:
   ```bash
   open MacClipboard.app
   ```
   *(Look for the clipboard icon in your top right menu bar!)*

## 📦 Sharing the App

If you want to share the compiled application with others, do not share the `.app` folder directly as it will lose macOS file permissions. Instead, use the `MacClipboard.zip` file automatically generated during the build process!

When someone else runs the `.app` for the very first time, they will need to **Right-Click -> Open** it to bypass macOS Gatekeeper's unidentified developer warning.
