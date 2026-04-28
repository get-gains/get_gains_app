# Flutter + Unity: Repo Setup

The Android app embeds a Unity build. The Unity export (`android/unityLibrary`) is **not** in the repo because it’s large and generated. You add it locally by exporting from the Unity project.

---

## Prerequisites

- Flutter SDK, Android SDK, NDK (e.g. 27.2.12479018 for Unity 6000.0)
- Unity **6000.0** with the [flutter_embed_unity](https://github.com/learntoflutter/flutter_embed_unity) export flow
- Your Unity project set up for Flutter embedding (see `UNITY_AGENT_PROMPT.md` for the bridge script)

---

## 1. Clone and open the Flutter repo

```bash
git clone <repo-url>
cd get_gains_app
flutter pub get
```

Do **not** run `flutter run` yet — the Android build will fail until `unityLibrary` is present.

---

## 2. Export Unity into this repo

In **Unity**:

1. Open your Unity 6000.0 project (the one that has the `FlutterUnityBridge` scene/script).
2. Use the **flutter_embed_unity** export (e.g. **File → Build Settings → Export for Flutter** or the plugin’s export option).
3. When the plugin asks for an export path, choose:
   - **`<path-to-this-repo>/get_gains_app/android/unityLibrary`**  
     i.e. the `android/unityLibrary` folder inside this Flutter project.

If the plugin exports to a different folder (e.g. `unityLibrary` on your desktop), **copy that entire folder** into:

```text
get_gains_app/android/unityLibrary
```

So that this path exists:

```text
get_gains_app/android/unityLibrary/build.gradle
get_gains_app/android/unityLibrary/src/main/jniLibs/arm64-v8a/libmain.so
...
```

---

## 3. Android local config (one-time)

From the repo root:

```bash
cd android
```

- If Android Studio or Flutter hasn’t created `local.properties`, create it with:
  - `sdk.dir=<path-to-android-sdk>`
  - (Optional) any Unity/NDK paths the Unity `build.gradle` expects, if required by the export.)

`local.properties` is gitignored; each developer sets it locally.

---

## 4. Build and run

From the **repo root** (`get_gains_app`):

```bash
flutter run
```

Or open the project in Android Studio and run the app. Use an **ARM64** device or an emulator with **arm64-v8a** (or “Translated ABI: arm64-v8a”); the Unity libs are ARM-only.

---

## Summary

| Step | Action                                                                             |
| ---- | ---------------------------------------------------------------------------------- |
| 1    | Clone repo, `flutter pub get`                                                      |
| 2    | Export Unity into `android/unityLibrary` (or copy the exported folder there)       |
| 3    | Ensure `android/local.properties` has `sdk.dir` (and any required Unity/NDK paths) |
| 4    | `flutter run` on an ARM64 device or emulator                                       |

After you change the Unity scene or scripts, **re-export** to `android/unityLibrary` and rebuild the Flutter app.

---

## Cursor MCP (optional)

The monorepo root (`get-gains-master`) includes **`.cursor/mcp.json`** registering a stdio MCP server **`unity-flutter-build`**. Open **that folder** as the Cursor workspace root so `${workspaceFolder}` resolves correctly. After you run **`npm install`** once in `tools/mcp-unity-flutter-build/`, restart Cursor; then tools such as **`export_unity_android`**, **`dart_build_runner`**, **`flutter_build_apk`**, and **`export_and_build`** can refresh `android/unityLibrary` and run Flutter-related commands without hand-copying exports.

- **`export_unity_android`** runs Unity batch export, then by default **`fvm dart run build_runner build --delete-conflicting-outputs`** in `get_gains_app`. Pass **`runCodegen: false`** to skip codegen.
- **`export_and_build`** runs export, then codegen (default on; set **`runCodegen: false`** to skip), then **`fvm flutter build apk`**.
- **`dart_build_runner`** runs only codegen in `get_gains_app` (same flags as above).
- Set **`UNITY_EDITOR`** to your Unity executable if auto-detection fails (see `scripts/export-unity-android-to-flutter.ps1` / `.sh` in the monorepo root).
- From the shell, the same export scripts support optional codegen: **`-RunCodegen`** on the `.ps1`, or **`--run-codegen`** on the `.sh`.
- Unity batch export is **slow**; approve or enable auto-run for these tools in Cursor as you prefer.
- MCP does not watch the filesystem by itself: ask the agent to run the export tool after Unity changes, or invoke the tool from the MCP tools list.
