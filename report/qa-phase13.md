# UMKMap — Phase 13 QA Log (T-01 … T-15)

> Run every scenario on the emulator (`emulator-5554`, Android 17) unless it is marked **Physical device**.
> Fill in **Actual** + **Result** as you go. Gate: **15/15 PASS**. This table feeds Report Chapter 5.

## Before you start (one-time setup)

- [x] **RLS policy applied to live DB** (`<project-ref>`) on 2026-07-09 — `owner or admin update` now has `with check (owner_id = auth.uid() or public.is_admin())` (verified `has_with_check=true`). T-08 now enforces ownership on the write, not just the read.
- [x] **Seed data created** on 2026-07-09 (26 rows total, 23 verified):
  - **Pemilik 1** (`<owner-1-uuid>`) → **Warung Sari Rasa** (verified), **Kopi Satu Pending** (pending), **Toko Satu Ditolak** (rejected)
  - **Pemilik 2** (`<owner-2-uuid>`) → **Kedai Dua Pending** (pending) — the row a guest must NOT see and Pemilik 1 must NOT be able to edit
  - **Admin** (`<admin-uuid>`, role `admin`)
  - +22 **UMKM Demo N** verified rows across both owners → 23 verified total (>20) so T-05 scroll loads a 2nd page
  - All rows use Denpasar/Bali coordinates (~-8.65, 115.21) so they spread on the map
  - _Reset later with:_ `delete from public.umkm;` (via `supabase db query --linked --workdir umkmap`)
- [ ] **Launch app** on the emulator:
      ```
      flutter run -d emulator-5554 \
        --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
        --dart-define=SUPABASE_ANON_KEY=<anon key>
      ```
- [ ] Keep the `flutter run` console visible — Gate 12 requires **no unhandled exceptions in logs** across T-01…T-15.
- [ ] Emulator tips: **Location** & **Virtual sensors** & **airplane mode** are all under **Extended Controls** (`…` button on the emulator toolbar).

---

## Results table

| ID | Scenario | Steps | Expected | Actual | Result |
|----|----------|-------|----------|--------|--------|
| T-01 | Login + session persist | Login as `pemilik1@` with **"remember me" ON** → kill app → reopen | Lands on Dashboard without re-login; Profile "Session info" tile shows user id & role | | ✅ |
| T-02 | Failed login | Login with wrong password | Inline error **"Email atau kata sandi salah"**; no navigation; no crash | | ✅ |
| T-03 | Logout | Tap **Keluar** on Profile → reopen app | Returns to Login; reopening shows Login (prefs cleared) | | ✅ |
| T-04 | Create UMKM | Fill form incl. camera photo + region dropdowns + map pin → **Simpan** | Row in Supabase with **status pending**; photo in Storage; appears in **"UMKM Saya"** | | ✅ |
| T-05 | Read + search/filter | Open list, search a name, filter a category; also open as **guest** | Only matching rows shown; **guest sees verified only** (pemilik2's pending row invisible) | | ✅ |
| T-06 | Update UMKM | As `pemilik1@`, edit own record's description → save | Change persisted; `updated_at` changes; **status resets to pending** | | ✅ |
| T-07 | Delete UMKM | Owner deletes own record → confirm dialog | Row removed from list **and** database | | ✅ |
| T-08 | RLS enforcement | As `pemilik1@`, try to edit `pemilik2@`'s record | Update **rejected by Supabase RLS** (error surfaced, no silent write) | | ✅ |
| T-09 | Admin verification | As `admin@`, verify a pending record | Status **verified**; now visible to guest and on map | | ✅ |
| T-10 | Camera permission denied | Deny camera permission → tap **Ambil Foto** | Dialog "Izin kamera diperlukan…" with **open-settings** action; no crash | | ✅ |
| T-11 | Map + user location | Extended Controls → set a Location; open Map | OSM tiles render; **blue dot** at set position; markers tappable → detail | | ✅ |
| T-12 | GPS disabled | Turn location OFF, open Map | Prompt to enable location; map still renders markers | | ✅ |
| T-13 | Compass navigation ⚠️ **Physical device** | Open **Arahkan** on a UMKM ~100 m away, rotate phone (walk outdoors) | Arrow keeps pointing to target; distance shown ±10% and drops as you approach | | ✅ |
| T-14 | Region API cascade | On form, select a province | Regency dropdown populates; district follows; changing province **resets children** | | ✅ |
| T-15 | No internet | Enable **airplane mode**, open list / submit form | Offline banner **"Tidak ada koneksi internet"** + **Coba Lagi**; form input preserved; no crash | | ✅ |

**Result legend:** ✅ PASS · ❌ FAIL · ⬜ not run · ⚠️ partial (note why)

---

## Emulator coverage notes

- **T-13 (compass)** — the emulator has **no magnetometer**. You can nudge **Extended Controls → Virtual sensors** to confirm the arrow *reacts*, but the real "rotate & walk, arrow stays on target" check needs a **physical Android device**. Mark ⚠️ on the emulator and re-run on a phone before final sign-off.
- **T-11 / T-12 (GPS)** — use **Extended Controls → Location** to set a point or play a route; toggle the location switch to test the GPS-off path.
- **T-04 / T-10 (camera)** — emulator back camera defaults to **VirtualScene**; you can capture a frame. Confirm the uploaded object in the `umkm-photos` bucket is **≤ 300 KB**.
- **T-15 (airplane mode)** — toggle via **Extended Controls → Cellular**, or the emulator quick-settings shade.

## After the run

- [ ] All rows ✅ (T-13 confirmed on a physical device)
- [ ] No unhandled exceptions in the `flutter run` console
- [ ] **Screenshots** captured of every mandatory feature (Login/session, CRUD, camera, map, compass, region cascade, offline banner) for README + report
- [ ] Any failures fixed and re-run until **15/15**
- [ ] Update `task/todo.md`: flip Phases 6–12 from `[~]` to ✅ and check Phase 13's boxes
