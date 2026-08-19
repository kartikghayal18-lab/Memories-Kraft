import { requireSupabase } from './client';
import { requireAdmin } from './auth';

export async function createOrder({ shipping, items, discount = 0, shippingFee = 0 }) { const { data, error } = await requireSupabase().rpc('create_order', { p_shipping: shipping, p_items: items, p_discount: discount, p_shipping_fee: shippingFee }); if (error) throw error; return data; }
export async function getOrders() { await requireAdmin(); const { data, error } = await requireSupabase().from('orders').select('*, customer:customers(*), order_items(*)').order('created_at', { ascending: false }); if (error) throw error; return data; }
export async function getOrder(id) { await requireAdmin(); const { data, error } = await requireSupabase().from('orders').select('*, customer:customers(*), order_items(*), personalization_assets(*), order_notes(*)').eq('id', id).single(); if (error) throw error; return data; }
export async function updateOrderStatus(id, order_status) { await requireAdmin(); const { data, error } = await requireSupabase().from('orders').update({ order_status }).eq('id', id).select().single(); if (error) throw error; return data; }
export async function addOrderNote(order_id, note) { const user = await requireAdmin(); const { data, error } = await requireSupabase().from('order_notes').insert({ order_id, note, admin_user_id: user.id }).select().single(); if (error) throw error; return data; }
export async function updateShipping(id, shipping) { await requireAdmin(); const { data, error } = await requireSupabase().from('orders').update(shipping).eq('id', id).select().single(); if (error) throw error; return data; }
