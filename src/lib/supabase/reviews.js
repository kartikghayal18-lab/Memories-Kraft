import { requireSupabase } from './client';
import { requireAdmin } from './auth';
export async function getReviews() { await requireAdmin(); const { data, error } = await requireSupabase().from('reviews').select('*, product:products(name), customer:customers(name,email)').order('created_at', { ascending: false }); if (error) throw error; return data; }
export async function approveReview(id) { await requireAdmin(); const { data, error } = await requireSupabase().from('reviews').update({ status: 'approved' }).eq('id', id).select().single(); if (error) throw error; return data; }
export async function rejectReview(id) { await requireAdmin(); const { data, error } = await requireSupabase().from('reviews').update({ status: 'rejected' }).eq('id', id).select().single(); if (error) throw error; return data; }
