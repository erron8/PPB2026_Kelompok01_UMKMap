-- Let any authenticated user (all pemilik + admin) read every UMKM regardless of
-- status, so all owners share one global dashboard. Anonymous guests still see
-- verified rows only.
drop policy if exists "public read verified" on public.umkm;

create policy "public read verified" on public.umkm
  for select using (status = 'verified' or auth.role() = 'authenticated');
