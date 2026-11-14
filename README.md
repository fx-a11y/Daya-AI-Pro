# Daya AI Pro v0.4.2 — Swing + Gemini + US Entry Plan

## Perubahan
- Setiap kandidat menampilkan alasan tren (EMA20/50/200) dan momentum (RSI14).
- Level perencanaan Entry, Stop Loss, TP1, TP2, TP3 dihitung dari penutupan harian dan ATR14.
- Risk/Reward dihitung untuk ketiga target.
- Status `SETUP POTENSIAL`, `WAIT`, atau `DATA KURANG`; bukan perintah BUY otomatis.
- Gemini diminta menjelaskan alasan setiap saham, dasar Entry/TP/SL, Risk/Reward, risiko, dan kondisi pembatalan. Gemini dilarang mengarang data yang tidak tersedia.
- Money Management tidak meminta modal: panduan risiko 1% per transaksi, batas rugi harian 2%, maksimal 3 posisi, break-even setelah TP1 sebagai pertimbangan, dan trailing stop berbasis swing low/ATR.
- API Key Api.co.id dan Gemini disimpan di secure storage perangkat.

## Batas data dan risiko
- Paket Api.co.id Free yang digunakan pada rancangan ini dibatasi 500 hit/bulan.
- Satu scan mengambil daftar instrumen dan maksimal 18 riwayat harian. Jadi Top 10 berasal dari batch terbatas, bukan pemindaian penuh seluruh BEI.
- Data yang dipakai adalah candle harian/EOD, bukan real-time/intraday. Entry, TP, SL merupakan level referensi, bukan harga eksekusi atau jaminan target.
- Money Management adalah panduan manual. Aplikasi belum terhubung ke saldo, posisi, atau eksekusi broker; tidak menghitung lot dan tidak dapat memaksa batas rugi.
- Analisis saat ini belum mencakup volume, order book/spread, foreign flow, fundamental, berita per emiten, pajak/biaya broker, dan slippage. Gemini tidak boleh mengarang metrik tersebut.

## Update ke proyek GitHub yang sudah ada
1. Ekstrak ZIP.
2. Timpa `lib/main.dart`, `pubspec.yaml`, dan `README.md` pada repository Flutter.
3. Pertahankan folder `android/` dan `.github/workflows/` yang sudah ada.
4. Commit perubahan dan jalankan GitHub Actions.
5. Jika build berhasil, unduh APK dari artifact dan instal untuk memperbarui APK lama.

## API Key
- Api.co.id: menu Lainnya → Atur API Key Api.co.id.
- Gemini: menu Lainnya → Atur API Key AI Gemini.
- Jangan memasukkan API Key ke source code atau commit ke GitHub.
- Penyimpanan key di aplikasi Android tetap memiliki risiko ekstraksi dari APK/perangkat. Untuk aplikasi publik, gunakan backend pribadi.

## Gemini
Menggunakan endpoint `gemini-2.5-flash`. Ketersediaan model dapat berbeda menurut akun/region dan dapat berubah; jika Google mengembalikan error model tidak ditemukan/tidak didukung, model perlu disesuaikan dengan model yang aktif pada Google AI Studio.


## v0.4.3 – Perbaikan Entry Saham Indonesia
- Zona entry BEI memakai EMA20 jika masih dekat dengan harga penutupan; jika terlalu jauh, memakai pullback berbasis ATR yang dibatasi agar area tidak lebih dari sekitar 3% di bawah harga terakhir.
- Stop Loss dan TP1–TP3 dihitung ulang dari zona entry dan ATR14.
- Masa berlaku rencana entry dihitung 5 hari kerja dari tanggal candle harian terakhir. Setelah lewat, level entry/SL/TP disembunyikan dan ditandai EXPIRED.
- Perhitungan hari kerja belum memasukkan hari libur resmi BEI. Jika tanggal candle tidak tersedia dari API, aplikasi memberi peringatan bahwa masa berlaku tidak dapat diverifikasi.
