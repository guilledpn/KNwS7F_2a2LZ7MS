export function Stats() {
  return (
    <section className="screen on">
      <div className="stats-head">
        <div className="screen-title">Estadísticas</div>
        <div className="screen-sub">Placeholder React. Debe reproducir Stats de App_llamados_v1.05 antes de mejorar.</div>
      </div>
      <div className="segment">
        <button className="on">Hoy</button>
        <button>Semana</button>
        <button>Mes</button>
      </div>
      <div className="scroll">
        <div className="metric-grid">
          <div className="metric full"><div className="metric-label">Misión útil de hoy</div><div className="metric-number">0 / 0</div></div>
          <div className="metric"><div className="metric-label">Llamados hoy</div><div className="metric-number">0</div></div>
          <div className="metric"><div className="metric-label">Agendas hoy</div><div className="metric-number">0</div></div>
        </div>
      </div>
    </section>
  );
}
