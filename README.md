# Auralis

A free, privacy-first music player for Android (with Windows and Linux builds available from the same source).

## Build the Android APK

No local setup is needed — GitHub builds it for you:

1. Push this repository to GitHub.
2. Open the **Actions** tab → **Build Auralis APK** → wait for the green tick.
3. Download the `auralis-apk` artifact and install `app-arm64-v8a-debug.apk` on your phone.

To build locally instead: install Flutter, then run `flutter pub get` and `flutter build apk --split-per-abi`.

## Before you publish releases

Links inside the app (About page, share text, update checker) point to
`https://github.com/kruthagna-j/auralis-app`. Replace `kruthagna-j`
with your GitHub username. In PowerShell, from the project folder:

```powershell
Get-ChildItem -Recurse -File -Include *.dart,*.json,*.md | ForEach-Object {
  (Get-Content $_.FullName -Raw) -replace 'kruthagna-j','your-real-username' | Set-Content $_.FullName -NoNewline
}
```

## License

Auralis is free software licensed under the **GNU General Public License v3.0 or later** (see `LICENSE`).
See `NOTICE.md` for attribution required by that license.
