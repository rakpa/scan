# Doc Scanner (MVP)

A cross-platform (Android-first, iOS-ready) document scanner built with Flutter +
Material 3, Riverpod, go_router, and Drift. This MVP delivers: **scan → persist →
multi-page PDF export → document library**.

> Branding is intentionally generic ("Doc Scanner", indigo seed color). Swap the
> app name, package id, and `AppTheme._seed` once branding is decided.

---

## What works in this MVP

- **Scan** a document (auto edge detection, corner adjust, multi-page, gallery
  import) via the native scanner — ML Kit Document Scanner on Android, VisionKit
  on iOS.
- **Persist** pages to disk + metadata in SQLite (Drift). Survives restarts.
- **Library**: reactive grid of documents with thumbnails, page count, date.
- **Detail**: view all pages; **rename**, **delete**, and **export to PDF** +
  share via the system share sheet.

Filters, OCR, folders/search, app lock, barcode/ID modes, and Drive sync are
scoped for v1/v2 (see the plan).

---

## Project layout

```
lib/
├── main.dart                      # ProviderScope + runApp
├── app/                           # MaterialApp.router, theme, go_router
├── core/
│   ├── providers/                 # db, storage, uuid singletons
│   └── storage/                   # DocumentStorage (on-disk page files)
├── data/database/                 # Drift AppDatabase (Documents, Pages)
└── features/
    ├── scan/                      # native scanner wrapper + controller
    ├── documents/                 # entities, repository, list & detail UI
    └── export/                    # PDF build + share
```

Each feature follows Clean Architecture: `domain` (entities + repository
interface) ← `data` (Drift/plugin impls) ← `presentation` (Riverpod + widgets).

---

## First-time setup

This repo contains the Dart source + `pubspec.yaml`, but **not** the generated
`android/`, `ios/`, and Drift `*.g.dart` files. Generate them locally:

```bash
# 1. Generate the native platform folders in-place (keeps lib/ + pubspec).
flutter create --org com.yourcompany --project-name doc_scanner .

# 2. Fetch dependencies.
flutter pub get

# 3. Generate Drift code (creates lib/data/database/database.g.dart).
dart run build_runner build --delete-conflicting-outputs

# 4. Run.
flutter run
```

> Until step 3 runs, `database.dart` shows analyzer errors referencing
> `database.g.dart` and `_$AppDatabase` — that's expected; codegen resolves them.

---

## Native configuration (apply after `flutter create .`)

### Android — `android/app/build.gradle`

```gradle
android {
    defaultConfig {
        minSdkVersion 24        // required by spec; ML Kit needs 21+
        targetSdkVersion flutter.targetSdkVersion
    }
}
```

### Android — `android/app/src/main/AndroidManifest.xml`

Inside `<manifest>` (camera is used by the scanner):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

> The ML Kit Document Scanner downloads its model via Google Play Services on
> first use. It will **not** work on devices/emulators without Play Services.

### iOS — `ios/Runner/Info.plist`

Inside the top-level `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to scan documents.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo access to import documents from your library.</string>
```

Set the iOS deployment target to **13.0** (VisionKit requirement) in Xcode or
`ios/Podfile` (`platform :ios, '13.0'`).

---

## Known flags / decisions

- **`cunning_document_scanner`** — free, on-device. Android requires Google Play
  Services; verify on a real device, not a bare emulator.
- **`image` package (v1)** — pure Dart, slow on large photos; filter work will
  run in an isolate (`compute`) to avoid UI jank.
- **Google Drive sync (v2)** — Drive scopes are *sensitive*; production needs
  Google's OAuth verification (privacy policy + review, weeks of lead time).
  Start that process early if Drive is needed sooner.
- All dependencies are free/OSS (BSD/MIT/Apache). No paid SDKs.

---

## Next (v1 priorities)

Enhancement filters (auto/B&W/grayscale/magic color) · folders, tags, FTS5
search · OCR (copy/export text) · JPG/PNG export + page-size/quality options ·
app lock (PIN/biometric) · QR/barcode + ID-card modes.
