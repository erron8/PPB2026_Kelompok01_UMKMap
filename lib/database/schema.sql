-- UMKMap Supabase schema.
-- Run once in the Supabase SQL Editor.

-- 1. profiles: 1-to-1 with auth.users, holds role
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text,
  role text not null default 'pemilik'
    check (role in ('admin', 'pemilik')),
  poin integer not null default 0,
  created_at timestamptz not null default now()
);

-- 2. kategori_umkm: seeded lookup table
create table public.kategori_umkm (
  id serial primary key,
  nama text not null unique,
  icon text
);

-- 3. umkm: core table
create table public.umkm (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id),
  nama_usaha text not null,
  nama_pemilik text not null,
  kategori_id int not null references public.kategori_umkm(id),
  deskripsi text,
  alamat_jalan text,
  provinsi_id text not null,
  provinsi_nama text not null,
  kota_id text not null,
  kota_nama text not null,
  kecamatan_id text not null,
  kecamatan_nama text not null,
  latitude double precision not null,
  longitude double precision not null,
  foto_url text,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index umkm_status_idx on public.umkm(status);
create index umkm_kategori_idx on public.umkm(kategori_id);
create index umkm_owner_idx on public.umkm(owner_id);

-- Row Level Security
alter table public.umkm enable row level security;
alter table public.profiles enable row level security;

create or replace function public.is_admin() returns boolean as $$
  select exists (select 1 from public.profiles
                 where id = auth.uid() and role = 'admin');
$$ language sql security definer;

-- Anonymous guests can read verified UMKM; authenticated users can read all UMKM
create policy "public read verified" on public.umkm
  for select using (status = 'verified' or auth.role() = 'authenticated');

-- Owners insert their own rows
create policy "owner insert" on public.umkm
  for insert with check (owner_id = auth.uid() or public.is_admin());

-- Owners update/delete own rows; admins anything (incl. status changes)
create policy "owner or admin update" on public.umkm
  for update using (owner_id = auth.uid() or public.is_admin())
  with check (owner_id = auth.uid() or public.is_admin());
create policy "owner or admin delete" on public.umkm
  for delete using (owner_id = auth.uid() or public.is_admin());

-- profiles: users read/update own profile; admins read all
create policy "own profile" on public.profiles
  for select using (id = auth.uid() or public.is_admin());
create policy "update own profile" on public.profiles
  for update using (id = auth.uid());

-- A) Auto-create profile on signup (name passed via auth metadata)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'Pengguna'),
    'pemilik'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- B) Keep updated_at fresh + prevent resetting status to pending for Super Users (points > 400)
create or replace function public.umkm_before_update()
returns trigger as $$
declare
  user_points int;
begin
  new.updated_at := now();
  select poin into user_points from public.profiles where id = new.owner_id;
  if not public.is_admin() and coalesce(user_points, 0) <= 400 then
    new.status := 'pending';
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger umkm_before_update
  before update on public.umkm
  for each row execute function public.umkm_before_update();

-- C) Auto-approve Super User UMKMs on INSERT (Tier 5: points > 400)
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

create trigger umkm_before_insert
  before insert on public.umkm
  for each row execute function public.umkm_before_insert();

-- D) Handle point rewards and penalties on insert or update
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
      end if;
    end if;
    
  -- 3. -50 Points penalty for owner when status changes to 'rejected' from pending/verified
  elsif (TG_OP = 'UPDATE' and new.status = 'rejected' and old.status != 'rejected') then
    update public.profiles
    set poin = greatest(0, poin - 50)
    where id = new.owner_id;
  end if;

  return new;
end;
$$ language plpgsql security definer;

create trigger umkm_after_insert_or_update
  after insert or update on public.umkm
  for each row execute function public.umkm_handle_points();

-- C) Seed categories
insert into public.kategori_umkm (nama) values
  ('Kuliner'), ('Fashion'), ('Kerajinan'), ('Jasa'), ('Pertanian'), ('Lainnya')
on conflict (nama) do nothing;

-- D) Storage bucket + policies
insert into storage.buckets (id, name, public)
values ('umkm-photos', 'umkm-photos', true)
on conflict (id) do nothing;

create policy "public read photos" on storage.objects
  for select using (bucket_id = 'umkm-photos');
create policy "authenticated upload photos" on storage.objects
  for insert with check (bucket_id = 'umkm-photos' and auth.role() = 'authenticated');
create policy "authenticated update photos" on storage.objects
  for update using (bucket_id = 'umkm-photos' and auth.role() = 'authenticated');
create policy "authenticated delete photos" on storage.objects
  for delete using (bucket_id = 'umkm-photos' and auth.role() = 'authenticated');
