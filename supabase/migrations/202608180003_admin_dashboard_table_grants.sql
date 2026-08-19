-- PostgreSQL grants are checked before RLS. These grants do not bypass RLS.
-- Row access remains governed by the existing customer and admin policies.

grant usage on schema public to authenticated;
grant execute on function public.is_admin() to authenticated;

grant select on table
  public.profiles,
  public.orders,
  public.order_items,
  public.products,
  public.product_images,
  public.product_categories,
  public.categories,
  public.customers,
  public.inventory_movements,
  public.reviews,
  public.coupons
to authenticated;
