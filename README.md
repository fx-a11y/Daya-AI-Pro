# Daya AI Pro — API integration awal

Flutter app untuk menghubungkan data BEI dari Api.co.id.

## Fitur versi 0.2
- Input API Key Api.co.id melalui menu **Lainnya**; disimpan memakai `flutter_secure_storage`.
- Mengambil daftar instrumen dengan endpoint `/idx/v2/instruments?index=IHSG&limit=100`.
- Screener daftar instrumen dan pencarian kode/nama; pengurutan perubahan harga penutupan harian.
- Analisis EMA20, EMA50, RSI14 dari endpoint daily EOD untuk ticker yang diminta.
- Feed berita pasar dari endpoint `/idx/v2/news`.
- Error handling untuk key belum diatur, respons gagal, dan timeout.

## Batas paket Free
Paket Free memiliki 500 hit/bulan. Endpoint daftar instrumen, daily EOD, dan berita tersedia. Quote live dan candle intraday (termasuk 5 menit) memerlukan paket Starter. Karena itu aplikasi ini **belum mengeluarkan sinyal scalping, Entry, TP, atau SL**. Analisis yang tersedia memakai candle harian dan hanya untuk riset/backtest awal.

## Menjalankan
1. `flutter pub get`
2. `flutter run`
3. Buka **Lainnya > Atur API Key**, tempel API Key Api.co.id.
4. Buka Beranda lalu tekan **Uji koneksi & muat saham**.

## Membuat APK
`flutter build apk --release`

## Keamanan
Key disimpan di secure storage perangkat dan tidak ditulis di source code. Ini lebih baik daripada hardcode, tetapi bukan pengganti backend: untuk distribusi publik, pindahkan request API ke backend dan simpan key di environment server. Jangan unggah APK yang berisi key pribadi ke publik.
