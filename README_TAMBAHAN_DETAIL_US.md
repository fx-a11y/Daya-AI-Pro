# Update v0.4.2 — Detail US + Rencana Entry Swing

## Fitur
- Menekan ticker membuka halaman Detail Saham AS.
- Menampilkan harga USD, perubahan harian, volume, rata-rata volume 20 hari, dan RVOL.
- Menghitung EMA20, EMA50, RSI14, dan ATR14 dari candle harian Yahoo Finance.
- Menampilkan status BUY SETUP / WAIT / NO TRADE.
- Jika BUY SETUP, menampilkan zona entry, Stop Loss, TP1, dan TP2.
- Rencana entry berlaku sampai 5 hari bursa perkiraan sejak candle data terakhir. Setelah tanggal itu, aplikasi menandai sinyal EXPIRED.

## Cara memperbarui repository
1. Ekstrak ZIP.
2. Timpa `lib/main.dart`, `scripts/build_us_screener.py`, dan `pubspec.yaml` di repository.
3. Timpa file workflow `update-us-screener.yml` bila diperlukan; workflow yang sudah ada tetap dapat digunakan.
4. Commit perubahan ke branch `main`.
5. Jalankan workflow Update US Screener secara manual untuk menghasilkan JSON baru.
6. Jalankan workflow Build Daya AI Pro APK untuk membuat APK terbaru.

## Catatan penting
- Data bersifat harian/EOD, bukan real-time.
- Perhitungan entry menggunakan EMA20/50, RSI14, ATR14, dan RVOL sebagai filter sederhana swing; bukan prediksi pasti.
- Masa 5 hari bursa dihitung dengan hari kerja Senin–Jumat dan belum mengabaikan seluruh hari libur bursa AS.
- Bila status EXPIRED, jangan gunakan harga entry lama. Jalankan pembaruan data dan tunggu rencana baru.
- Tidak ada jaminan profit; gunakan ukuran posisi dan risiko yang sesuai.
