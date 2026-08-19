-- Complete admin operations repair. PostgreSQL grants are required before RLS
-- policies are evaluated; neither the grants nor these policies bypass RLS.
-- All browser access remains limited to authenticated users whose profile role
-- is admin, as determined by public.is_admin().

grant usage on schema public, storage to authenticated;
grant execute on function public.is_admin() to authenticated;

grant select, insert, update, delete on table
  public.profiles,
  public.categories,
  public.products,
  public.product_categories,
  public.product_images,
  public.customers,
  public.orders,
  public.order_items,
  public.personalization_assets,
  public.order_notes,
  public.inventory_movements,
  public.coupons,
  public.reviews
to authenticated;

grant select, insert, update, delete on storage.objects to authenticated;
grant select on storage.buckets to authenticated;

do $$
declare
  managed_table text;
  policy_name text;
begin
  foreach managed_table in array array[
    'profiles', 'categories', 'products', 'product_categories', 'product_images',
    'customers', 'orders', 'order_items', 'personalization_assets', 'order_notes',
    'inventory_movements', 'coupons', 'reviews'
  ] loop
    execute format('alter table public.%I enable row level security', managed_table);
    policy_name := 'admin full access ' || managed_table;

    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = managed_table
        and policyname = policy_name
    ) then
      execute format(
        'create policy %I on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())',
        policy_name,
        managed_table
      );
    end if;
  end loop;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'admin full access product images'
  ) then
    execute 'create policy "admin full access product images" on storage.objects for all to authenticated using (bucket_id = ''product-images'' and public.is_admin()) with check (bucket_id = ''product-images'' and public.is_admin())';
  end if;
end $$;

-- Ensure the existing Auth account is represented by a database-backed role.
-- This never creates an Auth user and does not touch any password.
insert into public.profiles (id, role)
select id, 'admin'::public.profile_role
from auth.users
where lower(email) = 'memory@kraft.in'
on conflict (id) do update set role = excluded.role;
