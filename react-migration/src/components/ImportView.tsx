export function ImportView() {
  return (
    <section className="screen on">
      <div className="import-head">
        <div className="screen-title">Importar</div>
        <div className="screen-sub">Base React sin carga real todavía.</div>
      </div>
      <div className="scroll">
        <div className="import-card">
          <div className="card-title">Tipo de carga</div>
          <div className="import-types">
            <button className="type-card on">Mensual</button>
            <button className="type-card">Asignados</button>
          </div>
        </div>
        <div className="import-card">
          <button className="drop-zone">Seleccionar archivo</button>
        </div>
      </div>
    </section>
  );
}
