import { createClient } from '@supabase/supabase-js';

export const DEFAULT_SUPABASE_URL = 'https://lijibbhpyyptodneafdd.supabase.co';
export const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || DEFAULT_SUPABASE_URL;

// La anon/publishable key debe quedar en .env.local o en un entorno seguro de preview.
// Nunca usar service_role, JWT secret ni claves privadas en cliente.
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;

export const hasSupabaseConfig = Boolean(SUPABASE_URL && anonKey);
export const supabase = hasSupabaseConfig ? createClient(SUPABASE_URL, anonKey as string) : null;
