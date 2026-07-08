# UMKMap

## Identitas Project

**Nama aplikasi:** UMKMap

**Nama kelompok:** Kelompok UMKMap

**Nama anggota:**

- I GST. N. PT. Diana Putra Pratama (240040118)
- I Made Agastya Wedastika (240040120)
- I Made Bintang Kartika Yasa (240040054)

## Deskripsi

UMKMap adalah aplikasi mobile berbasis Flutter dan Supabase untuk pendataan serta pencarian UMKM. Aplikasi ini membantu pemilik usaha atau petugas memasukkan data UMKM lengkap dengan foto, alamat administratif, koordinat lokasi, dan status verifikasi.

## Permasalahan

Pendataan UMKM masih sering dilakukan menggunakan kertas atau spreadsheet terpisah, sehingga data mudah tidak sinkron, sulit diverifikasi, dan kurang akurat secara lokasi. Selain itu, banyak UMKM belum memiliki visibilitas digital yang baik sehingga sulit ditemukan oleh masyarakat sekitar.

## Solusi

UMKMap menyediakan aplikasi pendataan UMKM berbasis cloud dengan autentikasi pengguna, penyimpanan data di Supabase, pengunggahan foto usaha, pengambilan koordinat lokasi melalui peta, serta fitur verifikasi oleh admin. Data UMKM yang sudah terverifikasi dapat dilihat melalui daftar dan peta interaktif.

## Fitur

- Login, register, logout, dan penyimpanan sesi menggunakan SharedPreferences.
- Role pengguna untuk admin dan pemilik UMKM.
- CRUD data UMKM: tambah, lihat, ubah, dan hapus data usaha.
- Verifikasi data UMKM oleh admin.
- Pengambilan foto usaha menggunakan kamera.
- Daftar UMKM dengan pencarian dan filter.
- Peta OpenStreetMap untuk menampilkan lokasi UMKM.
- Pemilihan koordinat UMKM melalui peta.
- Kompas navigasi menuju lokasi UMKM.
- Dropdown wilayah Indonesia bertingkat: provinsi, kota/kabupaten, dan kecamatan.
- Penyimpanan data di Supabase Postgres dan foto di Supabase Storage.

## Teknologi

- Flutter
- Dart
- Supabase Auth
- Supabase Postgres
- Supabase Storage
- SharedPreferences
- Provider
- GoRouter
- OpenStreetMap dengan `flutter_map`
- Geolocator
- Flutter Compass
- Image Picker
- Flutter Image Compress
- HTTP API Wilayah Indonesia

## Cara Instalasi

1. Pastikan Flutter SDK, Android SDK, dan JDK sudah terpasang.
2. Clone atau buka repository project ini.
3. Masuk ke folder aplikasi:

   ```bash
   cd umkmap
   ```

4. Install dependency:

   ```bash
   flutter pub get
   ```

5. Jalankan aplikasi dengan konfigurasi Supabase:

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=isi_url_supabase \
     --dart-define=SUPABASE_ANON_KEY=isi_anon_key_supabase
   ```

6. Untuk membuat APK debug:

   ```bash
   flutter build apk --debug
   ```

## Pembagian Tugas

- I GST. N. PT. Diana Putra Pratama: Supabase, auth, routing.
- I Made Agastya Wedastika: CRUD UMKM, kamera, region API, README.
- I Made Bintang Kartika Yasa: map, lokasi, compass, UI polish.
