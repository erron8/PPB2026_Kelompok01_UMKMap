drop policy if exists "owner or admin update" on public.umkm;

create policy "owner or admin update" on public.umkm
  for update using (owner_id = auth.uid() or public.is_admin())
  with check (owner_id = auth.uid() or public.is_admin());
