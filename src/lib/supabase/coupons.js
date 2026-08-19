import { requireSupabase } from './client';
import { requireAdmin } from './auth';
export async function createCoupon(coupon) { await requireAdmin(); const { data, error } = await requireSupabase().from('coupons').insert(coupon).select().single(); if (error) throw error; return data; }
export async function updateCoupon(id, coupon) { await requireAdmin(); const { data, error } = await requireSupabase().from('coupons').update(coupon).eq('id', id).select().single(); if (error) throw error; return data; }
export async function validateCoupon(code, orderTotal) { const { data, error } = await requireSupabase().from('coupons').select('*').eq('code', code.toUpperCase()).eq('status', true).maybeSingle(); if (error) throw error; if (!data || (data.starts_at && new Date(data.starts_at) > new Date()) || (data.expires_at && new Date(data.expires_at) < new Date()) || (data.minimum_order && orderTotal < data.minimum_order)) return null; return data; }
