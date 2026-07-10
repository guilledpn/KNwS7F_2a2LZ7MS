export type ScreenId = 'contacts' | 'stats' | 'import' | 'settings';

export type ContactState =
  | 'pendiente'
  | 'agenda'
  | 'no_agenda'
  | 'volver'
  | 'no_contactado'
  | 'invalido'
  | 'gestionado';

export type ContactRow = {
  workItemId?: string;
  contactId: string;
  rut: string;
  nombre: string;
  campana?: string;
  campanaDescripcion?: string;
  origen?: string;
  estado: ContactState;
  telefonos: string[];
  email?: string;
};
