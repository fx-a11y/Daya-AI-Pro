# Daya AI Pro v0.2.1 — API Free + emiten interaktif

Perubahan:
- Daftar emiten di Beranda dan Screener sekarang bisa disentuh.
- Menyentuh emiten membuka halaman Detail Emiten.
- Detail Emiten otomatis meminta data candle harian dari Api.co.id dan menghitung EMA20, EMA50, RSI14, serta skor teknikal historis.
- Paket Free tidak menyediakan candle intraday 5 menit/quote live; aplikasi tidak membuat sinyal scalping palsu.
- API Key tetap dimasukkan dari menu Lainnya > Atur API Key dan disimpan menggunakan secure storage.

## Build
Jalankan `flutter pub get`, lalu build Android APK melalui workflow GitHub Actions yang sudah ada di repository.

Jika workflow membuat proyek Android dari nol, pastikan langkah `flutter create --platforms=android --project-name daya_ai_pro .` tetap dijalankan sebelum `flutter pub get`.
