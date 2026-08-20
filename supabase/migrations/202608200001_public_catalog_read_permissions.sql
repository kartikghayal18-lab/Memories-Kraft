-- Re-generated public storefront catalog repair. RLS remains enabled; these
-- grants only allow the anon role to reach the row-level policies below.
grant usage on schema public to anon;
grant select on table public.products, public.product_images, public.product_categories, public.categories to anon;

do $$
  egenrate public catlogbegin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'products' and policyname = 'catalog active products readable'
  ) then
    create policy "catalog active products readable"
      on public.products for select to anon
      using (status = 'active');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'product_images' and policyname = 'catalog images readable'
  ) then
    create policy "catalog images readable"
      on public.product_images for select to anon
      using (exists (
        select 1 from public.products
        where products.id = product_images.product_id and products.status = 'active'
      ));
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'product_categories' and policyname = 'catalog product categories readable'
  ) then
    create policy "catalog product categories readable"
      on public.product_categories for select to anon
      using (exists (
        select 1 from public.products
        where products.id = product_categories.product_id and products.status = 'active'
      ));
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'categories' and policyname = 'catalog active categories readable'
  ) then
    create policy "catalog active categories readable"
      on public.categories for select to anon
      using (status = true);
  end if;
end $$;
