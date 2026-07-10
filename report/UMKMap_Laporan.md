# Laporan Proyek UMKMap

**Mata kuliah:** Mobile Device Programming (TI253311)  
**Aplikasi:** UMKMap  
**Repository:** `PPB2026_Kelompok01_UMKMap`  
**Versi:** `1.0.0+14`

## Identitas Kelompok

| Nama | NIM |
| --- | --- |
| I GST. N. PT. Diana Putra Pratama | 240040118 |
| I Made Agastya Wedastika | 240040120 |
| I Made Bintang Kartika Yasa | 240040054 |

## Bab 1 - Pendahuluan

UMKMap adalah aplikasi pendataan UMKM berbasis Flutter dan Supabase. Aplikasi ini dibuat untuk membantu pemilik usaha, petugas lapangan, dan admin mengumpulkan data UMKM yang lebih rapi, terverifikasi, dan memiliki koordinat lokasi.

Masalah utama yang diselesaikan adalah pendataan UMKM yang masih tersebar di dokumen kertas atau spreadsheet, data lokasi yang hanya berbentuk alamat teks, dan rendahnya visibilitas UMKM lokal. UMKMap menawarkan solusi berupa aplikasi mobile dengan autentikasi, penyimpanan cloud, foto usaha, alamat administratif, koordinat peta, verifikasi admin, daftar publik, dan navigasi kompas menuju UMKM.

## Bab 2 - Analisis Kebutuhan

Kebutuhan fungsional utama:

| Kode | Kebutuhan | Implementasi |
| --- | --- | --- |
| FR-01 | Login dan session | Supabase Auth + SharedPreferences |
| FR-02 | Role routing | Admin, pemilik, dan guest melalui GoRouter |
| FR-03 | Create UMKM | Form UMKM lengkap dengan foto, wilayah, dan koordinat |
| FR-04 | Read UMKM | List, search, filter, detail, dan peta |
| FR-05 | Update/delete UMKM | Edit dan hapus dengan guard role |
| FR-06 | Verifikasi admin | Approve/reject status UMKM |
| FR-07 | Multi-page navigation | 9 halaman utama |
| FR-08 | Camera | Capture foto, kompres, upload |
| FR-09 | Map dan location | OpenStreetMap, marker, user location |
| FR-10 | Coordinate picker | Pilih titik UMKM di peta |
| FR-11 | Sensor kompas | Bearing ke target + jarak |
| FR-12 | API wilayah | API emsifa dan fallback asset |
| FR-13 | Cloud database | Supabase Postgres, Storage, RLS |

Kebutuhan non-fungsional meliputi keamanan RLS, tidak ada service-role key di APK, error state berbahasa Indonesia, offline banner, target Android 7.0 ke atas, dan struktur folder berlapis.

## Bab 3 - Perancangan Sistem

Arsitektur menggunakan pola berlapis:

```text
screens/widgets -> providers -> services -> Supabase/API/device
```

State management menggunakan Provider agar implementasi mudah diaudit dan cukup ringan untuk cakupan proyek. Screen tidak memanggil Supabase langsung; semua akses data melewati provider dan service.

Struktur folder utama:

```text
lib/
  models/
  services/
  providers/
  screens/
  widgets/
  database/
  utils/
```

Route utama:

- `/splash`
- `/login`
- `/register`
- `/dashboard`
- `/umkm`
- `/umkm/:id`
- `/umkm/form`
- `/map`
- `/profile`

## Bab 4 - Implementasi

Backend memakai Supabase Auth, Supabase Postgres, dan Supabase Storage. Tabel utama adalah `profiles`, `kategori_umkm`, dan `umkm`. RLS mengatur akses guest, pemilik, dan admin. Trigger signup membuat profil otomatis, sedangkan trigger update mengubah `updated_at` dan mengembalikan status ke `pending` ketika pemilik mengubah data.

Modul utama yang diimplementasikan:

- Auth dan session: `AuthService`, `SessionService`, `AuthProvider`
- CRUD UMKM: `UmkmService`, `UmkmProvider`, form/list/detail
- Storage foto: `StorageService`, `PhotoPickerField`
- Wilayah Indonesia: `WilayahApiService`, `WilayahDropdowns`
- Map dan lokasi: `LocationService`, `LocationProvider`, `MapScreen`
- Kompas: `CompassService`, `CompassArrow`, bottom sheet navigasi
- UI pendukung: card, status chip, loading/error, primary button

Konfigurasi Supabase dimasukkan lewat dart-define:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## Bab 5 - Pengujian

Regression QA Phase 13 telah dijalankan dengan hasil 15/15 PASS. Detail skenario dan catatan ada di `report/qa-phase13.md`.

| ID | Skenario | Status |
| --- | --- | --- |
| T-01 | Login + session persist | PASS |
| T-02 | Failed login | PASS |
| T-03 | Logout | PASS |
| T-04 | Create UMKM | PASS |
| T-05 | Read + search/filter | PASS |
| T-06 | Update UMKM | PASS |
| T-07 | Delete UMKM | PASS |
| T-08 | RLS enforcement | PASS |
| T-09 | Admin verification | PASS |
| T-10 | Camera permission denied | PASS |
| T-11 | Map + user location | PASS |
| T-12 | GPS disabled | PASS |
| T-13 | Compass navigation | PASS |
| T-14 | Region API cascade | PASS |
| T-15 | No internet | PASS |

Pengujian otomatis juga mencakup model, provider, wilayah dropdown, photo picker, compass service, map coordinate picker, routing/auth gate, dashboard, dan widget dasar.

## Bab 6 - Penutup

UMKMap memenuhi seluruh fitur wajib proyek: login/session, CRUD cloud database, multi-page navigation, camera, map/location, sensor kompas, API publik, dan Supabase sebagai database cloud. Aplikasi sudah memiliki gate QA yang lengkap dan release APK dapat dibuat melalui perintah build release.

Keterbatasan yang masih perlu diperhatikan sebelum pengumpulan adalah menempelkan screenshot final ke laporan PDF dan memastikan smoke test APK release pada perangkat Android bersih.

## Lampiran

- SQL schema: `lib/database/schema.sql`
- QA log: `report/qa-phase13.md`
- Screenshot fitur: `report/screenshots/`
- APK release: `umkmap/PPB2026_Kelompok01.apk`
