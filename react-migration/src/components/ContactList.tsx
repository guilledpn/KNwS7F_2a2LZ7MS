import { useEffect, useMemo, useState } from 'react';
import { getContacts } from '../lib/crmApi';
import type { ContactRow } from '../types';

function stateLabel(row: ContactRow): string {
  const labels: Record<string, string> = {
    pendiente: 'Pendiente',
    agenda: 'Agenda',
    no_agenda: 'No agenda',
    volver: 'Volver',
    no_contactado: 'No contactado',
    invalido: 'Inválido',
    gestionado: 'Gestionado'
  };
  return labels[row.estado] ?? row.estado;
}

function ContactCard({ row }: { row: ContactRow }) {
  return (
    <button className="contact-row">
      <span className="state-bar" />
      <span className="row-main">
        <span className="row-name">{row.nombre}</span>
        <span className="row-sub">{row.rut} · {row.campana || row.campanaDescripcion || 'Sin campaña'}</span>
      </span>
      <span className="row-side">
        {row.origen && <span className="state-label">{row.origen}</span>}
        <span className="state-label">{stateLabel(row)}</span>
      </span>
      <span className="row-chev">›</span>
    </button>
  );
}

export function ContactList() {
  const [rows, setRows] = useState<ContactRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;

    async function load() {
      try {
        setLoading(true);
        setError(null);
        const contacts = await getContacts();
        if (!alive) return;
        setRows(contacts);
      } catch (err) {
        if (!alive) return;
        setError(err instanceof Error ? err.message : 'No se pudieron cargar contactos');
      } finally {
        if (alive) setLoading(false);
      }
    }

    void load();
    return () => {
      alive = false;
    };
  }, []);

  const summary = useMemo(() => {
    if (loading) return 'Cargando contactos reales…';
    if (error) return 'Error al cargar contactos';
    if (!rows.length) return 'Sin contactos cargados. Revisa VITE_SUPABASE_ANON_KEY en entorno local.';
    return `${rows.length} contactos reales cargados desde Supabase`;
  }, [error, loading, rows.length]);

  return (
    <section className="screen on">
      <div className="search-wrap">
        <div className="search-box">Buscar nombre, RUT o teléfono</div>
      </div>
      <div className="filter-row">
        <button className="funnel-btn">Filtro</button>
        <button className="filter-chip on">Todos</button>
        <button className="filter-chip">Pendientes</button>
        <button className="filter-chip">Asignados</button>
      </div>
      <div className="scroll">
        <div className="contact-summary">{summary}</div>
        {error && <div className="empty-state">{error}</div>}
        <div className="list-card">
          {loading && <div className="empty-state">Cargando…</div>}
          {!loading && !error && rows.map((row) => <ContactCard row={row} key={row.workItemId || row.contactId} />)}
        </div>
      </div>
    </section>
  );
}
