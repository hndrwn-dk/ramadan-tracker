# Release Builds

Folder ini berisi file APK dan AAB yang sudah di-build untuk release.

## Format Nama File

- **APK**: `ramadan-tracker-v{VERSION}.apk`
- **AAB**: `ramadan-tracker-v{VERSION}.aab`

Dimana `{VERSION}` adalah versi dari `pubspec.yaml` (format: `x.y.z+buildNumber`)

## Cara Menggunakan

### Manual Copy
Setelah build, copy file secara manual:
```bash
# Setelah flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk releases/ramadan-tracker-v1.0.0+1.apk

# Setelah flutter build appbundle --release
cp build/app/outputs/bundle/release/app-release.aab releases/ramadan-tracker-v1.0.0+1.aab
```

### Menggunakan Script

**Windows:**
```bash
scripts\copy_releases.bat
```

**Linux/Mac:**
```bash
chmod +x scripts/copy_releases.sh
./scripts/copy_releases.sh
```

Script akan otomatis membaca version dari `pubspec.yaml` dan copy file dengan nama yang sesuai.

## Catatan

- File di folder ini **tidak akan terhapus** saat menjalankan `flutter clean`
- Folder `build/` akan terhapus saat `flutter clean`, tapi folder `releases/` tetap aman
- Pastikan untuk update version di `pubspec.yaml` sebelum build release baru

