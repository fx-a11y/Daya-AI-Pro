# Daya AI Pro v0.6.0 — Remote Device License (maksimal 5 perangkat)

## Perubahan
- Menambahkan Device ID acak 128-bit yang dibuat sekali dan disimpan di secure storage perangkat.
- Aplikasi memeriksa daftar izin dari `license/devices.json` di repository GitHub.
- Maksimal 5 entri perangkat. Status `ACTIVE` mengizinkan aplikasi; `BLOCKED` mencabut akses.
- Perangkat yang belum terdaftar menampilkan Device ID agar dapat disalin dan didaftarkan admin.
- Pemeriksaan ulang otomatis setiap 5 menit saat aplikasi berjalan.
- Jika server lisensi tidak dapat dihubungi, izin aktif terakhir diberi toleransi offline maksimum 24 jam. Pemblokiran jarak jauh baru berlaku pada perangkat saat perangkat kembali online dan berhasil mengambil konfigurasi terbaru.
- Tidak mengubah logika screener, analisis, PER/PBV, API BEI, maupun data saham AS.

## Cara update repository
ZIP ini adalah PATCH untuk repository yang sudah ada, bukan proyek Flutter lengkap.
1. Di repository `fx-a11y/Daya-AI-Pro`, ganti isi `lib/main.dart` dengan file dari ZIP.
2. Ganti `pubspec.yaml` dengan file dari ZIP.
3. Tambahkan file baru `license/devices.json` sesuai file dalam ZIP.
4. Commit perubahan. Jangan menghapus workflow GitHub Actions, `scripts/`, `data/`, atau GitHub Secrets yang sudah ada.
5. Jalankan workflow build APK yang biasa digunakan di tab Actions.
6. Pasang APK hasil build v0.6.0 pada semua HP yang akan dikendalikan. APK lama tidak memiliki pemeriksaan lisensi sehingga tidak dapat dikunci dari jauh.

## Mendaftarkan perangkat (maksimal 5)
1. Buka APK v0.6.0 pada HP. Pada layar lisensi, tekan **Salin Device ID**.
2. Di GitHub, edit `license/devices.json`.
3. Tambahkan satu objek untuk setiap HP. Contoh:

```json
{
  "schemaVersion": 1,
  "maxDevices": 5,
  "devices": [
    {"id": "TEMPEL_DEVICE_ID_HP_1", "label": "HP Utama", "status": "ACTIVE"},
    {"id": "TEMPEL_DEVICE_ID_HP_2", "label": "HP Kedua", "status": "ACTIVE"}
  ]
}
```

4. Commit perubahan. Kembali ke aplikasi dan tekan **Periksa kembali lisensi**. Ulangi untuk HP berikutnya sampai maksimal 5 entri.

## Mengunci / membuka perangkat
- Mengunci: ubah `status` perangkat menjadi `BLOCKED`, lalu commit.
- Membuka kembali: ubah `status` menjadi `ACTIVE`, lalu commit.
- Mengganti perangkat: hapus entri perangkat lama dan tambahkan Device ID baru. Maksimal 5 entri total.
- Hanya orang yang memiliki izin tulis ke repository GitHub yang dapat mengubah file kontrol tersebut.

## Catatan penting dan batasan
- Kedua HP wajib diperbarui sekali ke APK v0.6.0 atau lebih baru. APK versi lama tidak dapat menerima perintah blokir.
- Pemeriksaan online berjalan tiap 5 menit. GitHub/CDN dapat menunda propagasi perubahan.
- Toleransi offline 24 jam berarti pemblokiran tidak bisa berlaku seketika pada HP yang sedang offline. Setelah online, aplikasi mengambil status terbaru.
- Ini kontrol akses aplikasi berbasis klien, bukan penguncian sistem Android. Pengguna tingkat lanjut yang memodifikasi APK dapat mencoba melewati pemeriksaan; untuk lisensi komersial yang lebih kuat, pindahkan validasi ke backend privat.
- Jangan menaruh API key atau rahasia apa pun di `license/devices.json`; file tersebut diambil dari URL publik GitHub.
- Validasi build Flutter penuh harus dilakukan oleh GitHub Actions. Lingkungan penyusunan patch ini tidak memiliki Flutter SDK.
