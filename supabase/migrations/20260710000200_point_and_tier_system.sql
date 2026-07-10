-- Add points and tier columns to profiles table
alter table public.profiles add column if not exists poin integer not null default 0;
alter table public.profiles add column if not exists tier text not null default 'Bronze';

-- Create point_ledger and vouchers tables
create table if not exists public.point_ledger (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  poin_change integer not null,
  keterangan text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.vouchers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  subtitle text not null,
  cost integer not null,
  code text not null,
  created_at timestamptz not null default now()
);

-- Enable Row Level Security
alter table public.point_ledger enable row level security;
alter table public.vouchers enable row level security;

-- Drop existing policies if any
drop policy if exists "Users can view their own point ledger" on public.point_ledger;
drop policy if exists "Users can view their own vouchers" on public.vouchers;

-- Create policies
create policy "Users can view their own point ledger" on public.point_ledger
  for select using (profile_id = auth.uid() or public.is_admin());

create policy "Users can view their own vouchers" on public.vouchers
  for select using (profile_id = auth.uid() or public.is_admin());

-- Trigger to automatically update tier based on poin
create or replace function public.update_profile_tier()
returns trigger as $$
begin
  if new.poin <= 100 then
    new.tier := 'Bronze';
  elsif new.poin <= 200 then
    new.tier := 'Silver';
  elsif new.poin <= 300 then
    new.tier := 'Gold';
  elsif new.poin <= 400 then
    new.tier := 'Platinum';
  else
    new.tier := 'Super User';
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_profile_poin_change on public.profiles;
create trigger on_profile_poin_change
  before insert or update of poin on public.profiles
  for each row execute function public.update_profile_tier();

-- Update existing profiles to ensure correct tier matches current points
update public.profiles set tier = 
  case 
    when poin <= 100 then 'Bronze'
    when poin <= 200 then 'Silver'
    when poin <= 300 then 'Gold'
    when poin <= 400 then 'Platinum'
    else 'Super User'
  end;

-- Trigger to auto-approve Super User UMKMs on INSERT (points > 400)
create or replace function public.umkm_before_insert()
returns trigger as $$
declare
  user_points int;
begin
  select poin into user_points from public.profiles where id = new.owner_id;
  if coalesce(user_points, 0) > 400 then
    new.status := 'verified';
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists umkm_before_insert on public.umkm;
create trigger umkm_before_insert
  before insert on public.umkm
  for each row execute function public.umkm_before_insert();

-- Trigger umkm_before_update to:
-- a. Prevent resetting status to pending for Super Users (points > 400)
-- b. Restrict Verifikators (who are not the owner) to only update status column
create or replace function public.umkm_before_update()
returns trigger as $$
declare
  user_points int;
  updater_id uuid;
  updater_tier text;
begin
  new.updated_at := now();
  updater_id := auth.uid();

  -- Get owner points
  select poin into user_points from public.profiles where id = new.owner_id;

  -- If updater is not the owner and not admin, check if they are a Verifikator
  if updater_id is not null and updater_id != old.owner_id and not public.is_admin() then
    select tier into updater_tier from public.profiles where id = updater_id;
    if updater_tier in ('Gold', 'Platinum', 'Super User') then
      -- Ensure only status is updated
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
         new.owner_id is distinct from old.owner_id then
        raise exception 'Verifikator dilarang memanipulasi data profil usaha.';
      end if;
    else
      raise exception 'Anda tidak memiliki hak akses Verifikator.';
    end if;
  end if;

  -- Reset status to pending if updater is owner (or system) and is not Admin/Super User
  if not public.is_admin() and coalesce(user_points, 0) <= 400 then
    if updater_id is null or updater_id = old.owner_id then
      new.status := 'pending';
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists umkm_before_update on public.umkm;
create trigger umkm_before_update
  before update on public.umkm
  for each row execute function public.umkm_before_update();

-- Trigger to handle points allocation and penalties on INSERT and UPDATE
create or replace function public.umkm_handle_points()
returns trigger as $$
declare
  verifikator_id uuid;
  verifikator_points int;
  verifikator_role text;
begin
  -- 1. +20 Points for owner when status changes to 'verified'
  if (TG_OP = 'INSERT' and new.status = 'verified') or 
     (TG_OP = 'UPDATE' and new.status = 'verified' and old.status != 'verified') then
    
    update public.profiles
    set poin = poin + 20
    where id = new.owner_id;

    insert into public.point_ledger (profile_id, poin_change, keterangan)
    values (new.owner_id, 20, 'UMKM ' || new.nama_usaha || ' berhasil diverifikasi');
    
    -- 2. +10 Points for verifikator (excluding self-verification) if they are Gold tier or above or Admin
    verifikator_id := auth.uid();
    if verifikator_id is not null and verifikator_id != new.owner_id then
      select poin, role into verifikator_points, verifikator_role 
      from public.profiles 
      where id = verifikator_id;
      
      if verifikator_role = 'admin' or coalesce(verifikator_points, 0) > 200 then
        update public.profiles
        set poin = poin + 10
        where id = verifikator_id;

        insert into public.point_ledger (profile_id, poin_change, keterangan)
        values (verifikator_id, 10, 'Melakukan verifikasi UMKM ' || new.nama_usaha);
      end if;
    end if;
    
  -- 3. -50 Points penalty for owner when status changes to 'rejected' from pending/verified
  elsif (TG_OP = 'UPDATE' and new.status = 'rejected' and old.status != 'rejected') then
    update public.profiles
    set poin = greatest(0, poin - 50)
    where id = new.owner_id;

    insert into public.point_ledger (profile_id, poin_change, keterangan)
    values (new.owner_id, -50, 'Penalti data palsu/penipuan UMKM ' || new.nama_usaha);
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists umkm_after_insert_or_update on public.umkm;
create trigger umkm_after_insert_or_update
  after insert or update on public.umkm
  for each row execute function public.umkm_handle_points();

-- Update Row Level Security (RLS) on public.umkm
drop policy if exists "owner or admin update" on public.umkm;

create policy "owner or admin or verifikator update" on public.umkm
  for update using (
    owner_id = auth.uid() 
    or public.is_admin() 
    or exists (
      select 1 from public.profiles
      where id = auth.uid() and tier in ('Gold', 'Platinum', 'Super User')
    )
  )
  with check (
    owner_id = auth.uid() 
    or public.is_admin() 
    or exists (
      select 1 from public.profiles
      where id = auth.uid() and tier in ('Gold', 'Platinum', 'Super User')
    )
  );
