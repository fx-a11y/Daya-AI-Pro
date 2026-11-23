# Panduan update Daya AI Pro v0.6.0 lewat HP

1. Buka repository `fx-a11y/Daya-AI-Pro`.
2. Buka `lib/main.dart`, edit seluruh isi, ganti dengan `lib/main.dart` dari ZIP v0.6.0, lalu Commit.
3. Buka `pubspec.yaml`, ganti seluruh isi dengan `pubspec.yaml` dari ZIP v0.6.0, lalu Commit.
4. Buat folder `license` bila belum ada, lalu buat file `license/devices.json` dengan isi dari ZIP.
5. Jangan menghapus `.github/workflows`, `scripts`, `data`, atau GitHub Secrets.
6. Buka Actions dan jalankan workflow Build Daya AI Pro APK.
7. Pasang APK v0.6.0 di semua HP yang ingin dikendalikan. APK lama belum memiliki pemeriksaan lisensi.
8. Buka APK di setiap HP, salin Device ID, lalu masukkan ID itu ke `license/devices.json` dengan status `ACTIVE` (maksimal 5 entri). Commit dan tekan Periksa kembali lisensi di aplikasi.

Untuk memblokir HP: ubah status ID tersebut menjadi `BLOCKED` di `license/devices.json`, lalu Commit. Untuk mengaktifkan kembali: ubah menjadi `ACTIVE`.
