-- Tambahkan kolom detail_kategori ke tabel umkm
alter table public.umkm add column if not exists detail_kategori jsonb;

-- Perbarui fungsi umkm_before_update agar verifikator dilarang memanipulasi detail_kategori
create or replace function public.umkm_before_update()
returns trigger as $$
declare
  user_points int;
  updater_id uuid;
  updater_tier text;
begin
  new.updated_at := now();
  updater_id := auth.uid();

  -- Ambil poin pemilik UMKM
  select poin into user_points from public.profiles where id = new.owner_id;

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
         new.detail_kategori is distinct from old.detail_kategori then
        raise exception 'Verifikator dilarang memanipulasi data profil usaha.';
      end if;
    else
      raise exception 'Anda tidak memiliki hak akses Verifikator.';
    end if;
  end if;

  -- Reset status ke pending jika pengubah adalah pemilik dan bukan Admin/Super User
  if not public.is_admin() and coalesce(user_points, 0) <= 400 then
    if updater_id is null or updater_id = old.owner_id then
      new.status := 'pending';
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer;
