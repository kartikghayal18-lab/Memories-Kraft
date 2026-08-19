import { requireSupabase } from './client';

export async function signInWithPassword(email, password) { const { data, error } = await requireSupabase().auth.signInWithPassword({ email, password }); if (error) throw error; return data; }
export async function signOut() { const { error } = await requireSupabase().auth.signOut(); if (error) throw error; }
export async function getCurrentUser() { const { data, error } = await requireSupabase().auth.getUser(); if (error) throw error; return data.user; }
export async function requireAdmin() { const client = requireSupabase(); const user = await getCurrentUser(); if (!user) throw new Error('Authentication required.'); const { data, error } = await client.from('profiles').select('role').eq('id', user.id).single(); if (error) throw error; if (data.role !== 'admin') throw new Error('Admin access required.'); return user; }
