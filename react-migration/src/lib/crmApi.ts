import type { ContactRow } from '../types';
import { supabase } from './supabase';

export async function getContacts(): Promise<ContactRow[]> {
  if (!supabase) return [];
  const { data, error } = await supabase.rpc('get_contacts_v2', {
    p_active_period: null,
    p_search: '',
    p_situation: 'gestionables',
    p_pending_only: false,
    p_assigned_only: false,
    p_types: [],
    p_months: [],
    p_month_mode: 'any',
    p_limit: 50,
    p_offset: 0
  });

  if (error) throw error;
  const rows = data?.rows ?? [];
  return rows.map((row: any) => ({
    workItemId: row.work_item_id,
    contactId: row.contact_id,
    rut: row.rut || row.rut_norm || '',
    nombre: row.nombre || 'Sin nombre',
    campana: row.campaign_name,
    campanaDescripcion: row.campaign_desc,
    origen: row.origen,
    estado: 'pendiente',
    telefonos: [row.telefono_1, row.telefono_2, row.telefono_3].filter(Boolean),
    email: row.email
  }));
}
