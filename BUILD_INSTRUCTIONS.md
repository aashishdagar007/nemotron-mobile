# ⚡ Nemotron Code — Mobile (Android)

A full Flutter source project for a native Nemotron Code Android app.
Chat, file browser, in-app code editor with AI assist, settings — all powered by NVIDIA NIM.

This is a **complete source project**, not a pre-built APK — Flutter apps must be compiled
on a machine with the Flutter SDK + Android SDK installed (this can't be done in a
sandboxed environment). Building it yourself takes about 15 minutes, one-time setup.

---

## What's Included

```
lib/
├── main.dart                  Entry point
├── theme.dart                 Dark cyan/purple theme
├── models/message.dart        Chat message model
├── services/
│   ├── nim_service.dart       NVIDIA NIM streaming client
│   └── file_service.dart      File read/write/list/delete
├── screens/
│   ├── setup_screen.dart      First-launch API key entry
│   ├── home_screen.dart       Bottom nav (Chat / Files / Settings)
│   ├── chat_screen.dart       Streaming chat with reasoning trace
│   ├── files_screen.dart      File browser
│   ├── editor_screen.dart     Code editor + "Ask AI to edit" button
│   └── settings_screen.dart   API key, reasoning budget, reset
└── widgets/
    ├── message_bubble.dart    Markdown + code block rendering
    └── thinking_block.dart    Collapsible purple reasoning panel
android/                       Full Android project config
```

---

## Features

- 💬 **Chat** — streaming responses, reasoning trace, multi-key management, chat history, light/dark mode
- 📁 **File Browser** — navigate Android storage, create/delete files & folders
- ✏️ **Code Editor** — open any text/code file, edit manually, or tap **✨ Ask AI** to have Nemotron rewrite it
- 🖱️ **Device Control** — describe a task in plain English ("Open WhatsApp and message Mom"), and Nemotron will read the screen, decide the next tap/swipe/type action, execute it, and repeat until done
- ⚙️ **Settings** — API keys, reasoning budget, theme, reset

---

## ⚠️ About Device Control

This feature uses Android's **Accessibility Service** API — the same permission used by
screen readers, Tasker, and automation apps. It lets the app:

- Read the on-screen UI tree (text, buttons, positions) of **any** app
- Simulate taps, swipes, and text input **system-wide**

**This is intentionally powerful and requires you to manually enable it**:
Settings tab → Device Control → "Open Accessibility Settings" → find **Nemotron Code** → toggle on.

Google's Play Store restricts apps using this permission — since you're sideloading this
APK directly (not distributing via Play Store), that restriction doesn't apply to you.

**Use responsibly**: once enabled, the app can act in any app that's open. It only acts when
you type an instruction and tap Run — it does not run in the background uninstructed.

---



## How to Build the APK

### Step 1 — Install Flutter (one-time, ~10 min)

1. Download Flutter SDK: https://flutter.dev/docs/get-started/install
2. Extract it, add `flutter/bin` to your PATH
3. Verify:
   ```bash
   flutter doctor
   ```
4. Install **Android Studio** (needed for Android SDK + emulator/build tools)
   — flutter doctor will tell you if anything's missing

### Step 2 — Get the project files onto your machine

Download this folder, then:

```bash
cd nemotron-mobile
flutter pub get
```

### Step 3 — Build the APK

```bash
flutter build apk --release
```

This produces:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Step 4 — Install on your phone

**Option A — USB:**
```bash
flutter install
```

**Option B — Manual:**
Copy `app-release.apk` to your phone (via USB, Drive, Telegram, etc.) and tap to install.
You'll need to enable **"Install from unknown sources"** in Android settings.

---

## First Launch

1. App opens → asks for NVIDIA API key
2. Paste your `nvapi-...` key (free from build.nvidia.com)
3. Tap **Connect** — it tests the connection
4. You're in

---

## Permissions

The app requests storage permission on first use of the **Files** tab — needed to read/write
files on your device. Everything else (chat, settings) works without it.

---

## Notes on Capabilities vs Desktop

| Feature | Desktop (Python) | Mobile (Flutter) |
|---|---|---|
| Chat with reasoning | ✅ | ✅ |
| Read/write files | ✅ | ✅ |
| File browser | ✅ (terminal) | ✅ (native UI) |
| AI edits a file | ✅ | ✅ (via editor's Ask AI button) |
| Run shell commands | ✅ | ❌ (Android sandboxing blocks this without root) |
| Search across files | ✅ | Not yet — can be added |

For full terminal-command capability on Android, Termux + the Python version remains the only route (Android's app sandbox blocks arbitrary shell execution from regular apps — this is an OS-level restriction, not something fixable in code).

---

## Customizing

- App name/icon: edit `android/app/src/main/AndroidManifest.xml` and replace icons in `android/app/src/main/res/mipmap-*/`
- Colors: edit `lib/theme.dart`
- Package name: search-replace `com.nemotron.code` across the project
