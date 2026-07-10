-- Tambahkan kolom hari_operasional dan jam_operasional ke tabel umkm
alter table public.umkm add column if not exists hari_operasional text;
alter table public.umkm add column if not exists jam_operasional text;

-- Perbarui fungsi umkm_before_insert agar auto-approve untuk Gold tier ke atas
create or replace function public.umkm_before_insert()
returns trigger as $$
declare
  user_tier text;
begin
  select tier into user_tier from public.profiles where id = new.owner_id;
  if user_tier in ('Gold', 'Platinum', 'Super User') then
    new.status := 'verified';
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Perbarui fungsi umkm_before_update agar verifikator dilarang memanipulasi kolom baru,
-- dan pemilik dengan tier Gold ke atas tidak mengalami reset status ke pending saat update.
create or replace function public.umkm_before_update()
returns trigger as $$
declare
  user_tier text;
  updater_id uuid;
  updater_tier text;
begin
  new.updated_at := now();
  updater_id := auth.uid();

  -- Ambil tier pemilik UMKM
  select tier into user_tier from public.profiles where id = new.owner_id;

  -- Jika updater bukan pemilik data dan bukan admin, verifikasi apakah dia Verifikator
  if updater_id is not null and updater_id != old.owner_id and not public.is_admin() then
    select tier into updater_tier from public.profiles where id = updater_id;
    if updater_tier in ('Gold', 'Platinum', 'Super User') then
      -- Pastikan HANYA kolom status yang berubah
      if new.nama_usaha is distinct from old.nama_usaha or
         new.nama_pemilik is distinct from old.nama_pemilik or
         new.kategori_id is distinct from old.kategori_id or
         new.deskripsi is distinct from old.deskripsi or
         new.alamat_jalan is distinct from old.alamat_jalan or
         new.provinsi_id is distinct from old.provinsi_id or
         new.provinsi_nama is distinct from old.provinsi_nama or
         new.kota_id is distinct from old.kota_id or
         new.kota_nama is distinct from old.kota_nama or
         new.kecamatan_id is distinct from old.kecamatan_id or
         new.kecamatan_nama is distinct from old.kecamatan_nama or
         new.latitude is distinct from old.latitude or
         new.longitude is distinct from old.longitude or
         new.foto_url is distinct from old.foto_url or
         new.owner_id is distinct from old.owner_id or
         new.detail_kategori is distinct from old.detail_kategori or
         new.hari_operasional is distinct from old.hari_operasional or
         new.jam_operasional is distinct from old.jam_operasional then
        raise exception 'Verifikator dilarang memanipulasi data profil usaha.';
      end if;
    else
      raise exception 'Anda tidak memiliki hak akses Verifikator.';
    end if;
  end if;

  -- Reset status ke pending jika pengubah adalah pemilik dan bukan Admin/Gold/Platinum/Super User
  if not public.is_admin() and coalesce(user_tier, 'Bronze') not in ('Gold', 'Platinum', 'Super User') then
    if updater_id is null or updater_id = old.owner_id then
      new.status := 'pending';
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer;

-- Buat tabel public.reports
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  umkm_id uuid not null references public.umkm(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  tipe_laporan text not null,
  deskripsi text not null,
  foto_bukti_url text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

-- Enable RLS pada public.reports
alter table public.reports enable row level security;

-- Drop existing policies if any
drop policy if exists "Authenticated users can insert reports" on public.reports;
drop policy if exists "Users can view their own reports" on public.reports;
drop policy if exists "Admins can update reports status" on public.reports;

-- Buat policies baru
create policy "Authenticated users can insert reports"
  on public.reports for insert
  to authenticated
  with check (auth.uid() = reporter_id);

create policy "Users can view their own reports"
  on public.reports for select
  to authenticated
  using (auth.uid() = reporter_id or public.is_admin());

create policy "Admins can update reports status"
  on public.reports for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Buat trigger dan fungsi handle_report_status_change
create or replace function public.handle_report_status_change()
returns trigger as $$
begin
  -- Cek jika status berubah dari pending ke approved
  if old.status = 'pending' and new.status = 'approved' then
    -- 1. Berikan reward +15 Poin ke reporter
    update public.profiles
    set poin = coalesce(poin, 0) + 15
    where id = new.reporter_id;

    -- 2. Catat riwayat poin ke point_ledger
    insert into public.point_ledger (profile_id, poin_change, keterangan)
    values (new.reporter_id, 15, 'Laporan masalah UMKM disetujui: ' || new.tipe_laporan);

    -- 3. Jika tipe_laporan = 'Tutup Permanen', otomatis reject status UMKM
    if new.tipe_laporan = 'Tutup Permanen' then
      update public.umkm
      set status = 'rejected'
      where id = new.umkm_id;
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Pasang trigger ke tabel reports
drop trigger if exists tr_report_status_change on public.reports;
create trigger tr_report_status_change
  after update of status on public.reports
  for each row
  execute function public.handle_report_status_change();
