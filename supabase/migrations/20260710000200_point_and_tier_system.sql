-- Add points column to profiles table
alter table public.profiles add column if not exists poin integer not null default 0;

-- Trigger to auto-approve Super User UMKMs on INSERT (Tier 5: points > 400)
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

create or replace trigger umkm_before_insert
  before insert on public.umkm
  for each row execute function public.umkm_before_insert();

-- Update existing umkm_before_update function to prevent resetting status to pending for Super Users (points > 400)
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

create or replace trigger umkm_after_insert_or_update
  after insert or update on public.umkm
  for each row execute function public.umkm_handle_points();
