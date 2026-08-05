const dialog = document.querySelector('#appDialog');
const dialogEyebrow = document.querySelector('#dialogEyebrow');
const dialogTitle = document.querySelector('#dialogTitle');
const dialogBody = document.querySelector('#dialogBody');

const views = {
  hoy: ['Jornada', 'Hoy', '<p>La vista principal ya funciona como shell navegable. Los datos son ficticios y no representan gestiones reales.</p>'],
  personas: ['Núcleo', 'Personas', '<p>La próxima vertical incorporará búsqueda, ficha única e historial sin depender de las tablas Legacy.</p>'],
  agenda: ['Trabajo futuro', 'Agenda', '<p>Tareas y reuniones pertenecerán a Next. No se dividirán compromisos diarios entre dos aplicaciones.</p>'],
  stats: ['Vista derivada', 'Estadísticas', '<p>Las métricas se calcularán desde Actividades y hechos canónicos, nunca desde una cola convertida en fuente de verdad.</p>'],
  ajustes: ['Configuración', 'Ajustes', '<p>Los endpoints y claves de cada ambiente serán propios de Next. Ningún valor Legacy se incorpora por defecto.</p>']
};

function openDialog(eyebrow, title, html) {
  dialogEyebrow.textContent = eyebrow;
  dialogTitle.textContent = title;
  dialogBody.innerHTML = html;
  dialog.showModal();
}

document.querySelector('#environmentButton').addEventListener('click', () => {
  openDialog('Ambiente', 'NEXT-LOCAL', `
    <ul>
      <li>Frontend independiente en <code>apps/crm-patrimonial</code>.</li>
      <li>Backend local reservado en puertos 56321–56324.</li>
      <li>Sin conexión a LEGACY-DEV ni LEGACY-PROD.</li>
      <li>Los proyectos cloud están pendientes por límite de cuenta Supabase.</li>
    </ul>`);
});

document.querySelector('#startCallButton').addEventListener('click', () => {
  const previous = Number(localStorage.getItem('crmNextMockCalls') || '0');
  localStorage.setItem('crmNextMockCalls', String(previous + 1));
  openDialog('Demostración', 'Llamada iniciada', '<p>Esta acción sólo demuestra la interacción de la shell. No registra una Actividad ni escribe datos.</p>');
});

document.querySelector('#openPersonButton').addEventListener('click', () => {
  openDialog('Persona ficticia', 'Alejandra Pérez', '<p>La ficha real se implementará después del esquema físico <code>next_v03</code>. Esta vista no reutiliza la ficha de Legacy.</p>');
});

document.querySelector('#showQueueButton').addEventListener('click', () => {
  openDialog('Cola derivada', 'Próximas personas', '<p>La cola definitiva será reconstruible desde hechos del dominio. En esta etapa sólo se valida el contenedor visual y la navegación.</p>');
});

document.querySelectorAll('.nav-item').forEach((button) => {
  button.addEventListener('click', () => {
    document.querySelectorAll('.nav-item').forEach((item) => item.classList.remove('active'));
    button.classList.add('active');
    const [eyebrow, title, body] = views[button.dataset.view];
    if (button.dataset.view !== 'hoy') openDialog(eyebrow, title, body);
  });
});

if ('serviceWorker' in navigator && location.protocol.startsWith('http')) {
  window.addEventListener('load', () => navigator.serviceWorker.register('./sw.js'));
}
