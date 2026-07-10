import { hasSupabaseConfig, SUPABASE_URL } from '../lib/supabase';

export function Settings() {
  return (
    <section className="screen on">
      <div className="stats-head">
        <div className="screen-title">Ajustes</div>
        <div className="screen-sub">App_llamados React Migration · Hito 2 · Graphite</div>
      </div>
      <div className="scroll">
        <div className="card">
          <div className="card-title">Versión</div>
          <p>App_llamados_react_migration_hito_2</p>
        </div>
        <div className="card">
          <div className="card-title">Supabase runtime</div>
          <p>{hasSupabaseConfig ? 'Configurado para cargar datos reales.' : 'Sin VITE_SUPABASE_ANON_KEY. La app compila, pero no carga contactos reales.'}</p>
          <p className="muted-line">URL: {SUPABASE_URL}</p>
        </div>
        <div className="card">
          <div className="card-title">Regla visual</div>
          <p>No rediseñar. Primero reproducir App_llamados_v1.05.</p>
        </div>
      </div>
    </section>
  );
}
