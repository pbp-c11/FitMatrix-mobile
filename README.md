# fitmatrix_flutter

Flutter client for FitMatrix.

## API configuration

By default the app targets the deployed FitMatrix API:
- API base: `https://fadhil-daffa-fitmatrix.pbp.cs.ui.ac.id/api/`
- Media base: `https://fadhil-daffa-fitmatrix.pbp.cs.ui.ac.id`

Override via `--dart-define`:
- Android emulator (host machine backend): `FITMATRIX_API_BASE=http://10.0.2.2:8000/api/` and `FITMATRIX_MEDIA_BASE=http://10.0.2.2:8000`
- iOS simulator (host machine backend): `FITMATRIX_API_BASE=http://127.0.0.1:8000/api/` and `FITMATRIX_MEDIA_BASE=http://127.0.0.1:8000`

Example:

```bash
flutter run -d chrome \
  --dart-define=FITMATRIX_API_BASE=https://fadhil-daffa-fitmatrix.pbp.cs.ui.ac.id/api/ \
  --dart-define=FITMATRIX_MEDIA_BASE=https://fadhil-daffa-fitmatrix.pbp.cs.ui.ac.id
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
