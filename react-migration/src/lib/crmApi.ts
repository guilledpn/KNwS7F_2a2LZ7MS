import type { ContactRow, ContactState } from '../types';
import { supabase } from './supabase';

type RawContactRow = Record<string, unknown>;

function text(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function mapContact(row: RawContactRow): ContactRow {
  const estado: ContactState = 'pendiente';
  const telefonos = [row.telefono_1, row.telefono_2, row.telefono_3]
    .map(text)
    .filter((phone) => phone.length > 0);

  return {
    workItemId: text(row.work_item_id) || undefined,
    contactId: text(row.contact_id),
    rut: text(row.rut) || text(row.rut_norm),
    nombre: text(row.nombre) || 'Sin nombre',
    campana: text(row.campaign_name) || undefined,
    campanaDescripcion: text(row.campaign_desc) || undefined,
    origen: text(row.origen) || undefined,
    estado,
    telefonos,
    email: text(row.email) || undefined
  };
}

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

  const rows = Array.isArray(data?.rows) ? data.rows as RawContactRow[] : [];
  return rows.map(mapContact);
}
