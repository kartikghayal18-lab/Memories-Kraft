# Memory Kraft backend foundation

This storefront now includes a Supabase schema, RLS policies, storage policy definitions, and reusable browser data-access modules. It does not include an admin UI yet.

## Configure Supabase

1. Create a Supabase project and copy `.env.example` to `.env.local`.
2. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`; never expose the service-role key in Vite.
3. Run `supabase/migrations/202608170001_initial_ecommerce.sql` in the Supabase SQL editor or through the Supabase CLI.
4. Run `supabase/seed.sql` to migrate the six existing static catalogue entries as drafts. Add stock and set an item to `active` only when ready for customer visibility.
5. Create an owner account with Supabase Auth, then promote it once from the SQL editor: `update public.profiles set role = 'admin' where id = '<auth-user-uuid>';`.

The migration creates `product-images` (public) and `customer-personalization` (private) storage buckets. RLS is enabled on every application table. Customer personalization files are limited to their authenticated user folder; admins can access all files.

## Verification status

`npm run build` verifies the frontend and modules compile. Live Supabase connection, migrations, RLS, Auth, Storage, and CRUD require real project credentials and have not been claimed as verified without them.
