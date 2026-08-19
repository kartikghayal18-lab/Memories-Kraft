import { requireSupabase } from './client';
import { requireAdmin } from './auth';
export async function getCustomers() { await requireAdmin(); const { data, error } = await requireSupabase().from('customers').select('*').order('created_at', { ascending: false }); if (error) throw error; return data; }
export async function getCustomer(id) { await requireAdmin(); const { data, error } = await requireSupabase().from('customers').select('*').eq('id', id).single(); if (error) throw error; return data; }
export async function getCustomerOrders(customerId) { await requireAdmin(); const { data, error } = await requireSupabase().from('orders').select('*, order_items(*)').eq('customer_id', customerId).order('created_at', { ascending: false }); if (error) throw error; return data; }
