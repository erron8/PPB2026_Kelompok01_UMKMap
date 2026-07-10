# UMKMap

UMKMap adalah aplikasi mobile Flutter + Supabase untuk pendataan dan pencarian UMKM berbasis peta. Aplikasi ini dibuat untuk proyek akhir Mobile Device Programming (TI253311).

## Identitas Project

**Nama aplikasi:** UMKMap  
**Repository:** `PPB2026_Kelompok01_UMKMap`  
**Package Android:** `com.ppb2026.umkmap`  
**Versi release:** `1.0.0+15`

**Anggota kelompok:**

| Nama | NIM |
| --- | --- |
| I GST. N. PT. Diana Putra Pratama | 240040118 |
| I Made Agastya Wedastika | 240040120 |
| I Made Bintang Kartika Yasa | 240040054 |

## Deskripsi

UMKMap membantu pemilik usaha dan petugas lapangan mencatat data UMKM secara terstruktur: identitas usaha, pemilik, kategori, detail kategori dinamis, jam operasional, alamat administratif, koordinat GPS, foto usaha, dan status verifikasi. Data yang sudah diverifikasi dapat ditemukan publik melalui daftar UMKM dan peta OpenStreetMap.

## Permasalahan

Pendataan UMKM masih sering tersebar di kertas atau spreadsheet, sehingga data mudah tidak sinkron, sulit diverifikasi, dan tidak selalu memiliki titik koordinat yang akurat. Di sisi lain, UMKM lokal juga membutuhkan visibilitas digital agar lebih mudah ditemukan oleh masyarakat sekitar.

## Solusi

UMKMap menyediakan satu aplikasi cloud-backed dengan login berbasis role, CRUD data UMKM, unggah foto, koordinat peta, workflow verifikasi admin, sistem laporan UMKM, poin dan tier pengguna, profil yang dapat diperbarui, peta publik, dan kompas navigasi menuju lokasi UMKM. Sesi login disimpan dengan SharedPreferences sesuai kebutuhan proyek.

## Fitur Utama

| Kebutuhan wajib | Implementasi di UMKMap |
| --- | --- |
| Login dan session | Register, login, logout, auto-login, remember me, penyimpanan sesi dengan SharedPreferences, dan profil pengguna yang dapat diedit |
| CRUD data | Tambah, lihat, ubah, hapus UMKM berbasis Supabase Postgres, termasuk detail kategori dinamis serta hari/jam operasional |
| Multi-page navigation | 9 route: splash, login, register, dashboard, list, detail, form, map, profile |
| Camera | Ambil foto usaha dari kamera, kompres, lalu unggah ke Supabase Storage |
| Map dan location | OpenStreetMap, marker UMKM verified, user location, dan picker koordinat |
| Sensor | Kompas fungsional yang mengarah ke UMKM tujuan dan menampilkan jarak |
| API web service | Dropdown wilayah Indonesia bertingkat dari API emsifa, fallback asset, dan geocoding alamat via Nominatim |
| Cloud database | Supabase Auth, Postgres, Storage, RLS, policy, trigger, seed kategori, point ledger, voucher, dan reports |
| Sistem laporan | Pengguna terautentikasi dapat melaporkan UMKM bermasalah dengan foto bukti; admin meninjau laporan dari dashboard |
| Admin reporting tabs | Dashboard admin memuat antrean verifikasi UMKM dan laporan pending dengan detail, approve, dan reject |
| Poin dan tier | Profil menampilkan poin/tier; verifikasi, laporan disetujui, dan penalti status tercatat melalui trigger database |

## Tech Stack

- Flutter, Dart, Material 3
- Supabase Auth, Supabase Postgres, Supabase Storage
- SharedPreferences untuk session lokal
- Provider untuk state management
- GoRouter untuk named route dan guard
- `flutter_map` + OpenStreetMap untuk peta
- `geolocator` untuk lokasi GPS
- `flutter_compass` untuk heading sensor
- `image_picker` dan `flutter_image_compress` untuk foto usaha
- `http` untuk API wilayah Indonesia dan geocoding Nominatim
- `permission_handler` untuk alur izin kamera/lokasi
- `cached_network_image` untuk foto di list/detail

## Screenshot dan Bukti QA

Hasil regression QA lengkap ada di [`report/qa-phase13.md`](report/qa-phase13.md). File tersebut mencatat T-01 sampai T-15 dengan status 15/15 PASS, termasuk tes live Supabase, kamera, map, GPS, offline state, dan kompas pada perangkat fisik. Setelah merge fitur contributor, gate otomatis release juga hijau (`flutter analyze`, `flutter test`, dan `flutter build apk --release --dart-define-from-file=env.json`).

Screenshot deliverable tersimpan di [`report/screenshots/`](report/screenshots/):

| Bukti fitur | Layar yang disarankan |
| --- | --- |
| Login | [`login.png`](report/screenshots/login.png) |
| Dashboard owner | [`dashboard-owner.png`](report/screenshots/dashboard-owner.png) |
| Session SharedPreferences | [`profile-session.png`](report/screenshots/profile-session.png) |
| CRUD/list | [`umkm-list.png`](report/screenshots/umkm-list.png) |
| CRUD/detail | [`umkm-detail.png`](report/screenshots/umkm-detail.png) |
| CRUD/form | [`umkm-form.png`](report/screenshots/umkm-form.png) |
| Map dan location | [`map.png`](report/screenshots/map.png) |
| Sensor kompas | [`compass.png`](report/screenshots/compass.png) |
| Offline handling | [`offline.png`](report/screenshots/offline.png) |
| Admin verification | [`admin-verification.png`](report/screenshots/admin-verification.png) |
| Detail kategori + jam operasional | [`umkm-detail.png`](report/screenshots/umkm-detail.png) |
| Form kategori dinamis + jam operasional | [`umkm-form.png`](report/screenshots/umkm-form.png) |
| Sistem laporan UMKM | [`umkm-detail.png`](report/screenshots/umkm-detail.png) |
| Admin reporting tabs | [`admin-verification.png`](report/screenshots/admin-verification.png) |
| Poin, tier, dan edit profil | [`profile-session.png`](report/screenshots/profile-session.png) |

## Instalasi dan Menjalankan

1. Pastikan Flutter SDK, Android SDK, dan JDK sudah terpasang.
2. Masuk ke folder aplikasi:

   ```bash
   cd umkmap
   ```

3. Install dependency:

   ```bash
   flutter pub get
   ```

4. Jalankan aplikasi dengan dart-define Supabase:

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://PROJECT_ID.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=SUPABASE_ANON_KEY
   ```

5. Alternatif lokal menggunakan file ignored `env.json`:

   ```bash
   flutter run --dart-define-from-file=env.json
   ```

## Build APK Release

```bash
flutter build apk --release --dart-define-from-file=env.json
cp build/app/outputs/flutter-apk/app-release.apk PPB2026_Kelompok01.apk
```

APK final lokal berada di `PPB2026_Kelompok01.apk`. File APK tidak dimasukkan ke git karena ukurannya besar; unggah APK sebagai GitHub Release asset saat publikasi.

## Ringkasan Database

Tabel utama:

- `profiles`: profil pengguna dan role (`admin` / `pemilik`)
- `kategori_umkm`: kategori seed (`Kuliner`, `Fashion`, `Kerajinan`, `Jasa`, `Pertanian`, `Lainnya`)
- `umkm`: data usaha, alamat administratif, koordinat, foto, status verifikasi, detail kategori, hari operasional, dan jam operasional
- `reports`: laporan masalah UMKM dengan foto bukti dan status review admin
- `point_ledger`: riwayat perubahan poin pengguna
- `vouchers`: data voucher/reward pengguna

Keamanan:

- RLS aktif pada `profiles` dan `umkm`
- Guest hanya membaca UMKM `verified`
- Pengguna terautentikasi dapat membaca semua status UMKM untuk mendukung dashboard, daftar internal, dan verifikasi; perubahan data tetap dibatasi oleh policy owner/admin
- Pemilik membuat/mengubah/menghapus data sendiri
- Admin dapat memverifikasi semua data
- Trigger signup otomatis membuat row `profiles`
- Trigger update mengatur `updated_at` dan mengembalikan status ke `pending` ketika pemilik mengubah data
- Trigger poin/tier memberi reward atau penalti saat UMKM diverifikasi/ditolak dan saat laporan disetujui
- Tier Gold, Platinum, dan Super User dapat membantu verifikasi status sesuai policy dan trigger yang berlaku

SQL lengkap ada di [`lib/database/schema.sql`](lib/database/schema.sql).

## Pembagian Tugas

Pembagian berikut mengikuti bukti commit lokal saat README ini ditulis. `git shortlog -sne --all` menampilkan author commit berikut: `errondotsol <howlingdxd@gmail.com>` 40 commit, `aristokragus <agusdindin842@gmail.com>` 5 commit, dan `BintangKartika <bintangkartika3008@gmail.com>` 2 commit.

| Anggota / author commit | Bukti commit | Kontribusi yang terlihat di commit |
| --- | --- | --- |
| I Made Agastya Wedastika / `errondotsol <howlingdxd@gmail.com>` | 40 commits | Bootstrap Flutter, Supabase/auth/session, CRUD UMKM, camera/storage, API wilayah/geocoding, map/location, compass, dashboard/profile, hardening, QA, README, release deliverables |
| I GST. N. PT. Diana Putra Pratama / `aristokragus <agusdindin842@gmail.com>` | 5 commits | Sistem laporan, opsi jam operasional, admin reporting tabs, detail kategori dinamis, poin/tier, dan update profil |
| I Made Bintang Kartika Yasa / `BintangKartika <bintangkartika3008@gmail.com>` | 2 commits | Refactor struktur kode dan merge contributor |
