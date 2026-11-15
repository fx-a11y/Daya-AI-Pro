# Setup Twelve Data untuk Daya AI Pro

1. Buat akun di https://twelvedata.com/ dan salin API Key dari dashboard.
2. Buka repository GitHub `fx-a11y/Daya-AI-Pro`.
3. Masuk **Settings → Secrets and variables → Actions → New repository secret**.
4. Isi nama secret tepat: `TWELVE_DATA_API_KEY`.
5. Isi value dengan API Key Twelve Data, lalu simpan. Jangan tempel API Key ke file Dart, Python, README, atau chat.
6. Buka **Actions → Update US stock screener data → Run workflow**.
7. Pastikan langkah Build US stock screener berhasil dan file `data/us_stocks.json` ter-commit.
8. Jalankan workflow **Build Daya AI Pro APK** untuk membangun APK.

## Batas pemakaian
- Endpoint `/time_series` memakai 1 API credit per simbol.
- Workflow default mengambil sekitar 100 simbol. Pada paket Basic gratis Twelve Data, kuota yang ditampilkan saat ini adalah 8 API credits/menit dan 800/hari; cek dashboard akun karena paket dan kebijakan dapat berubah.
- Jeda default 8,2 detik antar simbol untuk menjaga laju request.
- Data timeframe 1day adalah candle harian, bukan tick real-time. Akses dan kedalaman data historis tergantung paket dan lisensi.
- Jika ingin mengganti watchlist, edit variabel `US_SYMBOLS` di workflow menjadi daftar ticker dipisahkan koma.
