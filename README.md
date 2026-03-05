# 📦 Deploy Packager

> **"Deploy what changed—don't carry the burden of manual sorting."**

Say goodbye to manual file picking! **Deploy Packager** is the evolution of [folder_sync_inspector](https://github.com/ekyaaa/folder_sync_inspector), redesigned specifically for developers dealing with *offline server deployments*. 🚀

If your production server is offline, has no GitHub access, and you're tired of manually digging through changed files from Git commits just to copy them... this app is your new best friend.

---

## 🎯 Background (The "Why")
This project is a sequel to **Folder Sync Inspector**. While the predecessor focused on inspecting folder synchronization, **Deploy Packager** focuses on **automatic extraction**.

This app was born from "productive laziness": moving only updated files to a production server while perfectly preserving the folder structure—minimizing the risk of "Web Down" dramas caused by misplaced files.

---

## 🛠️ How It Works (The Magic)
As simple as sipping your morning coffee:

1.  **Pick Project**: Select your Git repo folder. (The app is smart; it remembers your choice for tomorrow).
2.  **Select Commits**: Choose which commits you want to "bundle." Yes, you can select multiple!
3.  **Review Files**: View the list of changed files. There's a search filter to ensure no "secret" files accidentally tag along.
4.  **Export!**: Pick a destination, click generate, and *BOOM!* Your files are ready to be copied to the server with their original directory structure intact.

---

## 💻 Tech Stack (The Muscles)
Built with love and modern tech:
*   **Flutter Desktop**: Lightning-fast performance on Windows, Linux, and macOS.
*   **Material 3**: Modern, clean UI (Dark mode by default, because we are developers).
*   **Riverpod**: Solid, reactive state management.
*   **Git CLI**: Directly communicates with your local Git repository.
*   **Shared Preferences**: So the app doesn't have amnesia (remembers your last project/export paths).

---

## 🚀 How to Run
Ensure you have the Flutter SDK installed, then:

```bash
flutter pub get
flutter run
```

---

*Made with ❤️ by a developer who hates manual copy-paste.*
