# Daya AI Pro — Prototipe Flutter

Prototipe UI aplikasi analisis saham Indonesia. Tidak memerlukan VPS untuk dijalankan secara lokal.

## Yang tersedia
- Dashboard dengan data contoh
- AI Screener dengan filter interaktif
- Halaman Analisis Saham dan 8 Pilar
- Halaman Notifikasi
- Halaman Lainnya
- Navigasi bawah
- Tema gelap

## Catatan
Semua harga, skor, sinyal, dan nilai IHSG yang ditampilkan adalah data demo. Belum ada integrasi API, backend, database, AI, atau push notification nyata.

## Menjalankan
1. Pasang Flutter SDK dan Android Studio pada komputer.
2. Ekstrak ZIP ini.
3. Buka terminal di folder `daya_ai_pro_flutter`.
4. Jalankan:
   ```bash
   flutter pub get
   flutter run
   ```
5. Untuk membuat APK debug:
   ```bash
   flutter build apk --debug
   ```
   File APK akan berada di `build/app/outputs/flutter-apk/app-debug.apk`.

## Struktur
- `lib/main.dart` — seluruh UI prototipe
- `pubspec.yaml` — konfigurasi Flutter
