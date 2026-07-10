import { createClient } from '@supabase/supabase-js';

export const SUPABASE_URL = 'https://lijibbhpyyptodneafdd.supabase.co';

// La anon key debe quedar en variable de entorno antes de conectar datos reales.
// Nunca usar service_role ni claves privadas en cliente.
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;

export const supabase = anonKey ? createClient(SUPABASE_URL, anonKey) : null;
