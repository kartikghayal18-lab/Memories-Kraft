-- Repair migration: explicit dashboard read policies for database-backed admins.
-- Customer policies remain unchanged and RLS stays enabled on every table.

do $$ begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'orders' and policyname = 'admin dashboard orders read') then
    create policy "admin dashboard orders read" on public.orders for select using (public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'order_items' and policyname = 'admin dashboard order items read') then
    create policy "admin dashboard order items read" on public.order_items for select using (public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'products' and policyname = 'admin dashboard products read') then
    create policy "admin dashboard products read" on public.products for select using (public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'product_images' and policyname = 'admin dashboard product images read') then
    create policy "admin dashboard product images read" on public.product_images for select using (public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'categories' and policyname = 'admin dashboard categories read') then
    create policy "admin dashboard categories read" on public.categories for select using (public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'product_categories' and policyname = 'admin dashboard product categories read') then
    create policy "admin dashboard product categories read" on public.product_categories for select using (public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'customers' and policyname = 'admin dashboard customers read') then
    create policy "admin dashboard customers read" on public.customers for select using (public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'inventory_movements' and policyname = 'admin dashboard inventory read') then
    create policy "admin dashboard inventory read" on public.inventory_movements for select using (public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'reviews' and policyname = 'admin dashboard reviews read') then
    create policy "admin dashboard reviews read" on public.reviews for select using (public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'coupons' and policyname = 'admin dashboard coupons read') then
    create policy "admin dashboard coupons read" on public.coupons for select using (public.is_admin());
  end if;
end $$;
