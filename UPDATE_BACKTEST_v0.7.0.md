# Daya AI Pro v0.7.0 — Backtest & Probability Engine

## Isi update
- Menu Backtest baru di navigasi utama.
- Pilih pasar BEI atau Amerika Serikat.
- BEI: mengambil candle harian dari endpoint `/chart/daily/{symbol}` Api.co.id.
- AS: mengambil candle harian historis 5 tahun dari Yahoo Finance Chart API.
- Mesin simulasi strategi trend: Close > EMA20 > EMA50 > EMA200 dan RSI 50–70.
- Entry pada open candle berikutnya, SL 1,5 ATR, TP 3 ATR (target 2R), maksimum 20 candle.
- Statistik win rate, jumlah transaksi menang/kalah, rata-rata return, total return sederhana, profit factor, dan daftar transaksi.

## Cara update
1. Backup project lama.
2. Ekstrak ZIP ini.
3. Salin folder `lib/` dan file `pubspec.yaml` ke root project Flutter lama (replace file yang sama).
4. Jalankan `flutter pub get` lalu `flutter analyze`.
5. Build APK dengan `flutter build apk --release`.

## Catatan metodologi
- Butuh minimal 220 candle agar EMA200 tersedia.
- Jika TP dan SL tersentuh pada candle yang sama, SL dihitung lebih dulu.
- Hanya satu posisi aktif pada satu waktu.
- Win rate adalah frekuensi historis, bukan probabilitas pasti sinyal berikutnya.
- Belum memasukkan fee, pajak, slippage, corporate action, suspensi, delisting, survivorship bias, dan pembagian saham/dividen.
- Return total adalah penjumlahan persentase return transaksi, bukan CAGR atau simulasi portofolio berbobot modal.
- Data BEI mengikuti paket/kuota API yang digunakan. Data AS memerlukan akses internet dan ketersediaan endpoint Yahoo Finance.
