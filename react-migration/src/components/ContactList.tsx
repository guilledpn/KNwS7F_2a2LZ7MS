const rows = [
  { nombre: 'Contacto de referencia', rut: '00.000.000-0', campana: 'Campaña', estado: 'Pendiente' },
  { nombre: 'Tarjeta compacta Material You', rut: '11.111.111-1', campana: 'Asignado', estado: 'Agenda' }
];

export function ContactList() {
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
        <div className="contact-summary">Base visual React · sin datos reales todavía</div>
        <div className="list-card">
          {rows.map((row) => (
            <button className="contact-row" key={row.rut}>
              <span className="state-bar" />
              <span className="row-main">
                <span className="row-name">{row.nombre}</span>
                <span className="row-sub">{row.rut} · {row.campana}</span>
              </span>
              <span className="row-side"><span className="state-label">{row.estado}</span></span>
              <span className="row-chev">›</span>
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}
