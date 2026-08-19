insert into public.categories(name,slug) values ('Birthday','birthday'),('Anniversary','anniversary'),('Love','love'),('Friendship','friendship'),('Raksha Bandhan','raksha-bandhan'),('Best Friend','best-friend'),('Just Because','just-because'),('Custom','custom') on conflict(slug) do nothing;
insert into public.products(name,slug,short_description,price,sku,stock_quantity,low_stock_threshold,main_image,status,personalizable,photo_upload_required,max_photos,custom_text_allowed,max_text_length)
values ('Memory Bloom Box','memory-bloom-box','Photo + flower keepsake',1199,'MK-BLOOM-001',0,3,'/images/memory-kraft-hero.png','draft',true,true,6,true,240),('A Little Box of Us','a-little-box-of-us','Personalized photo cards',699,'MK-CARDS-001',0,3,'/images/memory-kraft-collection.png','draft',true,true,6,true,240),('Letters & Light','letters-and-light','Candle with a memory note',549,'MK-CANDLE-001',0,3,'/images/memory-kraft-collection.png','draft',true,false,0,true,240),('Forever Frame','forever-frame','Hand-finished photo frame',899,'MK-FRAME-001',0,3,'/images/memory-kraft-collection.png','draft',true,true,1,true,120),('The Mini Moment','the-mini-moment','Polaroids in a keepsake tin',499,'MK-MINI-001',0,3,'/images/memory-kraft-collection.png','draft',true,true,12,false,0),('Threads of Home','threads-of-home','Sibling memory hamper',999,'MK-RAKHI-001',0,3,'/images/memory-kraft-collection.png','draft',true,true,6,true,240) on conflict(slug) do nothing;

insert into public.product_categories(product_id, category_id)
select p.id, c.id
from (values
  ('memory-bloom-box', 'birthday'),
  ('memory-bloom-box', 'love'),
  ('a-little-box-of-us', 'anniversary'),
  ('letters-and-light', 'just-because'),
  ('forever-frame', 'custom'),
  ('the-mini-moment', 'friendship'),
  ('threads-of-home', 'raksha-bandhan')
) as mappings(product_slug, category_slug)
join public.products p on p.slug = mappings.product_slug
join public.categories c on c.slug = mappings.category_slug
on conflict do nothing;
