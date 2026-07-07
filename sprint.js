(() => {
  const KEY = 'crm_sprint_v1';
  let timer = null;
  let reportLoading = false;
  let reportDay = '';
  let block1 = '';
  let block2 = '';

  const $ = (id) => document.getElementById(id);
  const today = () => new Date().toISOString().slice(0, 10);
  const base = () => ({ workMin: 20, breakMin: 5, logs: [], active: null });
  const load = () => { try { return Object.assign(base(), JSON.parse(localStorage.getItem(KEY) || '{}')); } catch (e) { return base(); } };
  const save = (s) => { try { localStorage.setItem(KEY, JSON.stringify(s)); } catch (e) {} };
  const sbClient = () => { try { return sb || null; } catch (e) { return null; } };
  const fmt = (ms) => { ms = Math.max(0, ms); const t = Math.ceil(ms / 1000); return String(Math.floor(t / 60)).padStart(2, '0') + ':' + String(t % 60).padStart(2, '0'); };
  const remaining = (s) => !s.active ? 0 : (s.active.paused ? Math.max(0, Number(s.active.remainingMs || 0)) : Math.max(0, Number(s.active.endAt || 0) - Date.now()));

  function toast(msg) {
    try {
      if (navigator.vibrate) navigator.vibrate([90, 45, 90]);
      document.querySelectorAll('.crm-sprint-toast').forEach((x) => x.remove());
      const t = document.createElement('div');
      t.className = 'crm-sprint-toast';
      t.textContent = msg;
      document.body.appendChild(t);
      setTimeout(() => t.remove(), 2200);
    } catch (e) {}
  }

  function normalizeState(label) {
    const s = String(label || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
    if (s === 'agenda') return 'agenda';
    if (s === 'no agenda') return 'no_agenda';
    if (s === 'volver a llamar') return 'volver';
    if (s === 'no contactado') return 'no_contactado';
    if (s === 'invalido') return 'invalido';
    if (s === 'gestionado') return 'gestionado';
    return '';
  }

  function formatRut(rut) {
    const s = String(rut || '').trim();
    if (!s || s.includes('-')) return s;
    return s.length > 1 ? s.slice(0, -1) + '-' + s.slice(-1) : s;
  }

  function sprintStats(s) {
    const d = today();
    let sprints = 0, breaks = 0, minutes = 0;
    const items = [];
    (s.logs || []).forEach((x) => {
      if (x.date !== d) return;
      if (x.type === 'work_complete') { sprints++; minutes += Number(x.minutes || 0); items.push('Sprint ' + sprints + ' · ' + (x.minutes || 0) + ' min'); }
      if (x.type === 'break_complete') breaks++;
      if (x.type === 'cancelled') items.push('Cancelado');
    });
    return { sprints, breaks, minutes, items: items.slice(-3) };
  }

  function addStyles() {
    if ($('crm-sprint-style')) return;
    const css = document.createElement('style');
    css.id = 'crm-sprint-style';
    css.textContent = `
      :root{
        color-scheme:light;
        --bg:#f6f7f9;--surface:#ffffff;--surface-container-low:#f2f4f7;--surface-container:#e8edf3;--surface-container-high:#dfe5ec;
        --outline:#c8d0da;--outline-variant:#e0e5ec;--on-surface:#111827;--on-surface-variant:#374151;--muted:#667085;
        --primary:#334155;--primary-pressed:#1f2937;--primary-container:#e5e7eb;--on-primary:#fff;--on-primary-container:#111827;
        --success:#166534;--success-container:#dcfce7;--warning:#854d0e;--warning-container:#fef3c7;--danger:#b91c1c;--danger-container:#fee2e2;--neutral:#64748b;--neutral-container:#e2e8f0;
      }
      @media (prefers-color-scheme:dark){:root{color-scheme:dark;--bg:#0f1115;--surface:#171a21;--surface-container-low:#1d2129;--surface-container:#242936;--surface-container-high:#303747;--outline:#495164;--outline-variant:#303747;--on-surface:#f4f5f7;--on-surface-variant:#d4d8e1;--muted:#9aa3b2;--primary:#cbd5e1;--primary-pressed:#e2e8f0;--primary-container:#334155;--on-primary:#0f1115;--on-primary-container:#f8fafc;--success:#22c55e;--success-container:#12331f;--warning:#f59e0b;--warning-container:#3a2a0a;--danger:#ef4444;--danger-container:#3b1212;--neutral:#94a3b8;--neutral-container:#283142;}}
      #crm-sprint-chip{height:38px;border-radius:19px;font-weight:800;font-size:12.5px;padding:0 11px;display:flex;align-items:center;gap:6px;white-space:nowrap}
      #crm-sprint-chip.idle{background:var(--primary-container)!important;color:var(--on-primary-container)!important;border:1px solid var(--outline)!important;box-shadow:none!important}
      #crm-sprint-chip.running{background:#166534!important;color:#fff!important;border:0!important;box-shadow:0 6px 16px rgba(15,23,42,.14)!important}
      #crm-sprint-chip.warn{background:#b91c1c!important;color:#fff!important;border:0!important;box-shadow:0 6px 16px rgba(15,23,42,.14)!important}
      #crm-sprint-chip.paused{background:#64748b!important;color:#fff!important;border:0!important;box-shadow:0 6px 16px rgba(15,23,42,.14)!important}
      .crm-sprint-panel{position:fixed;inset:0;background:rgba(15,23,42,.36);z-index:9999;display:none;align-items:flex-end;justify-content:center}.crm-sprint-panel.on{display:flex}
      .crm-sprint-card{width:100%;max-width:520px;background:var(--surface);border-radius:26px 26px 0 0;padding:22px 20px calc(22px + env(safe-area-inset-bottom));box-shadow:0 -18px 45px rgba(15,23,42,.24)}
      .crm-sprint-card h3,#crm-sprint-stats-card h3,#crm-daily-report-card h3{margin:0 0 10px;font-size:18px;color:var(--on-surface)}.crm-sprint-card h3{font-size:22px}.crm-sprint-time{font-size:42px;font-weight:900;letter-spacing:-.04em;margin:8px 0;color:var(--on-surface)}.crm-sprint-muted,.crm-sprint-log{color:var(--muted);font-size:14px;line-height:1.35}.crm-sprint-row{display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin-top:14px}.crm-sprint-btn,.crm-report-copy{border:0;border-radius:18px;background:#111827;color:#fff;font-weight:800;padding:13px 16px}.crm-sprint-btn.secondary,.crm-report-copy.secondary{background:var(--surface-container);color:var(--on-surface)}.crm-sprint-btn.danger{background:#b91c1c}.crm-sprint-input{width:72px;border:1px solid var(--outline);border-radius:14px;padding:10px 11px;font-weight:800;background:var(--surface);color:var(--on-surface)}
      .crm-sprint-toast{position:fixed;left:20px;right:20px;bottom:calc(86px + env(safe-area-inset-bottom));z-index:10000;background:#111827;color:#fff;border-radius:18px;padding:14px 16px;text-align:center;font-weight:800;box-shadow:0 12px 28px rgba(15,23,42,.22)}
      #crm-sprint-stats-card,#crm-daily-report-card{background:var(--surface);border:1px solid var(--outline-variant);border-radius:22px;margin:0 0 12px;padding:14px;box-shadow:var(--shadow)}#crm-daily-report-card{margin-bottom:96px}.crm-sprint-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}.crm-sprint-metric{background:var(--surface-container-low);border:1px solid var(--outline-variant);border-radius:16px;padding:10px}.crm-sprint-metric b{display:block;font-size:20px;color:var(--on-surface)}.crm-sprint-metric span{font-size:11.5px;color:var(--muted)}.crm-sprint-log{margin-top:10px;font-size:13px}
      .crm-report-head{display:flex;align-items:center;justify-content:space-between;gap:10px;margin-bottom:6px}.crm-report-block{background:transparent;border:0;border-radius:0;padding:0;margin-top:12px}.crm-report-title{font-size:13px;font-weight:900;margin:0 0 6px;color:var(--on-surface)}.crm-report-pre{white-space:pre-wrap;font-family:var(--mono,ui-monospace,SFMono-Regular,Menlo,Consolas,monospace);font-size:12.5px;color:var(--on-surface-variant);background:var(--surface-container-low);border:1px solid var(--outline-variant);border-radius:14px;padding:10px;max-height:150px;overflow:auto}.crm-report-actions{display:flex;gap:8px;margin-top:8px;flex-wrap:wrap}.crm-report-copy{border-radius:14px;padding:9px 12px;font-size:13px}
      .settings-sheet .settings-note{display:none!important}.settings-section{padding:10px 2px 12px!important}.settings-label{margin-bottom:7px!important}.settings-actions{margin-top:4px!important}.settings-sheet .input-surface.compact,.settings-sheet .select-surface{min-height:44px!important;border-radius:14px!important}.settings-sheet .toggle-row{min-height:50px!important}.settings-sheet .toggle-title{font-size:14px!important}.settings-sheet .toggle-sub{display:none!important}#crm-sprint-settings .crm-sprint-row{margin-top:8px!important}
      @media(max-width:430px){#crm-sprint-chip{font-size:11.5px;padding:0 9px}.goal-chip{min-width:auto!important;padding:0 9px!important}.topbar{gap:8px!important}.crm-sprint-grid{grid-template-columns:repeat(2,1fr)}}`;
    document.head.appendChild(css);
  }

  function ensureChip() {
    const top = $('main-topbar');
    if (!top) return null;
    let chip = $('crm-sprint-chip');
    if (!chip) {
      chip = document.createElement('button');
      chip.id = 'crm-sprint-chip';
      chip.type = 'button';
      chip.innerHTML = '<span id="crm-sprint-chip-txt">Sprint</span>';
      const goal = top.querySelector('.goal-chip');
      top.insertBefore(chip, goal || top.querySelector('.icon-btn') || null);
    }
    chip.onclick = () => { load().active ? openPanel() : startSprint(); };
    return chip;
  }

  function startSprint() { const s = load(), now = Date.now(); s.active = { mode: 'work', startedAt: now, endAt: now + Math.max(1, Number(s.workMin || 20)) * 60000, paused: false, remainingMs: null }; save(s); toast('Sprint iniciado'); update(); }
  function pauseResume() { const s = load(); if (!s.active) return; if (s.active.paused) { const r = Math.max(1000, Number(s.active.remainingMs || 0)); s.active.paused = false; s.active.endAt = Date.now() + r; s.active.remainingMs = null; toast('Sprint reanudado'); } else { s.active.remainingMs = remaining(s); s.active.paused = true; toast('Sprint en pausa'); } save(s); update(); }
  function restartSprint() { const s = load(), now = Date.now(); s.active = { mode: 'work', startedAt: now, endAt: now + Math.max(1, Number(s.workMin || 20)) * 60000, paused: false, remainingMs: null }; save(s); toast('Sprint reiniciado'); update(); }
  function stopSprint() { const s = load(); if (s.active) { s.logs.push({ date: today(), type: 'cancelled', mode: s.active.mode, ts: Date.now() }); s.active = null; save(s); toast('Sprint detenido'); } closePanel(); update(); }
  function finishPhase(s) { if (!s.active || s.active.paused) return; if (s.active.mode === 'work') { s.logs.push({ date: today(), type: 'work_complete', minutes: Number(s.workMin || 20), ts: Date.now() }); s.active = { mode: 'break', startedAt: Date.now(), endAt: Date.now() + Math.max(1, Number(s.breakMin || 5)) * 60000, paused: false, remainingMs: null }; save(s); toast('Sprint completo. Descanso'); } else { s.logs.push({ date: today(), type: 'break_complete', minutes: Number(s.breakMin || 5), ts: Date.now() }); s.active = null; save(s); toast('Descanso terminado'); } update(); }

  function panel() { let p = $('crm-sprint-panel'); if (p) return p; p = document.createElement('div'); p.id = 'crm-sprint-panel'; p.className = 'crm-sprint-panel'; p.innerHTML = '<div class="crm-sprint-card"><h3>Sprint de llamados</h3><div class="crm-sprint-muted" id="crm-sprint-sub"></div><div class="crm-sprint-time" id="crm-sprint-time">20:00</div><div class="crm-sprint-muted" id="crm-sprint-mini-stats"></div><div class="crm-sprint-row"><button class="crm-sprint-btn" id="crm-sprint-pause">Pausar</button><button class="crm-sprint-btn secondary" id="crm-sprint-restart">Reiniciar</button><button class="crm-sprint-btn danger" id="crm-sprint-stop">Detener</button><button class="crm-sprint-btn secondary" id="crm-sprint-close">Cerrar</button></div></div>'; document.body.appendChild(p); p.onclick = (e) => { if (e.target === p) closePanel(); }; $('crm-sprint-pause').onclick = pauseResume; $('crm-sprint-restart').onclick = restartSprint; $('crm-sprint-stop').onclick = stopSprint; $('crm-sprint-close').onclick = closePanel; return p; }
  function openPanel() { panel().classList.add('on'); update(); }
  function closePanel() { const p = $('crm-sprint-panel'); if (p) p.classList.remove('on'); }

  async function copyText(text) { try { await navigator.clipboard.writeText(text); toast('Copiado'); } catch (e) { toast('No se pudo copiar'); } }

  async function loadReport(force = false) {
    const d = today();
    if (!force && reportDay === d && block1 && block2) return;
    if (reportLoading) return;
    const client = sbClient(); if (!client) return;
    reportLoading = true;
    try {
      const { data, error } = await client.from('crm_log').select('work_item_id,rut_norm,estado_nuevo,created_at,fecha').gte('fecha', d).lte('fecha', d).order('created_at', { ascending: true });
      if (error) throw error;
      const last = {}; (data || []).forEach((r) => { if (r.work_item_id) last[r.work_item_id] = r; });
      const rows = Object.values(last), counts = { agenda: 0, no_agenda: 0, volver: 0, no_contactado: 0, invalido: 0, gestionado: 0 };
      rows.forEach((r) => { const k = normalizeState(r.estado_nuevo); if (counts[k] != null) counts[k]++; });
      const agendaRows = rows.filter((r) => normalizeState(r.estado_nuevo) === 'agenda');
      const ids = agendaRows.map((r) => r.work_item_id).filter(Boolean), names = {};
      if (ids.length) { const { data: wq } = await client.from('work_queue').select('work_item_id,nombre,rut_norm').in('work_item_id', ids); (wq || []).forEach((r) => { names[r.work_item_id] = r; }); }
      const agendas = agendaRows.map((r) => { const w = names[r.work_item_id] || {}; return { nombre: w.nombre || 'Sin nombre', rut: formatRut(w.rut_norm || r.rut_norm || '') }; }).sort((a, b) => a.nombre.localeCompare(b.nombre, 'es'));
      const total = counts.agenda + counts.no_agenda + counts.volver + counts.no_contactado + counts.invalido + counts.gestionado;
      const effective = counts.agenda + counts.no_agenda;
      block1 = 'Agendamientos\n' + (agendas.length ? agendas.map((x) => '- ' + x.nombre + (x.rut ? ' · ' + x.rut : '')).join('\n') : '- Sin agendamientos');
      block2 = 'Reporte\nLlamadas totales: ' + total + '\nLlamadas efectivas: ' + effective + '\nAgendan: ' + counts.agenda + '\nNo Agenda: ' + counts.no_agenda;
      reportDay = d;
    } catch (e) { block1 = 'Agendamientos\n- Error al cargar datos'; block2 = 'Reporte\nLlamadas totales: 0\nLlamadas efectivas: 0\nAgendan: 0\nNo Agenda: 0'; reportDay = d; }
    finally { reportLoading = false; }
  }

  function mountSettings() { const version = $('crm-version-section'); if (!version || $('crm-sprint-settings')) return; const s = load(); const el = document.createElement('div'); el.className = 'settings-section'; el.id = 'crm-sprint-settings'; el.innerHTML = '<label class="settings-label">Sprint</label><div class="crm-sprint-row"><label class="settings-label" style="margin:0;text-transform:none;letter-spacing:0">Llamados <input id="crm-sprint-work" class="crm-sprint-input" type="number" min="1" max="180" value="' + s.workMin + '"></label><label class="settings-label" style="margin:0;text-transform:none;letter-spacing:0">Descanso <input id="crm-sprint-break" class="crm-sprint-input" type="number" min="1" max="60" value="' + s.breakMin + '"></label></div><div class="crm-sprint-row"><button class="crm-sprint-btn" id="crm-sprint-start-settings">Iniciar</button><button class="crm-sprint-btn secondary" id="crm-sprint-save-settings">Guardar</button></div>'; version.parentNode.insertBefore(el, version); $('crm-sprint-save-settings').onclick = () => { const n = load(); n.workMin = Math.max(1, Number($('crm-sprint-work').value || 20)); n.breakMin = Math.max(1, Number($('crm-sprint-break').value || 5)); save(n); toast('Sprint configurado'); update(); }; $('crm-sprint-start-settings').onclick = startSprint; }

  function mountStats() {
    const sc = $('stats-scroll'); if (!sc) return;
    const screen = $('screen-stats'); if (screen && !screen.classList.contains('on')) return;
    let sprintCard = $('crm-sprint-stats-card'); if (!sprintCard) { sprintCard = document.createElement('div'); sprintCard.id = 'crm-sprint-stats-card'; sc.insertBefore(sprintCard, sc.firstChild); }
    const s = load(), st = sprintStats(s), status = s.active ? ((s.active.paused ? 'En pausa · ' : (s.active.mode === 'work' ? 'Sprint en curso · ' : 'Descanso en curso · ')) + fmt(remaining(s))) : 'Sin sprint activo';
    sprintCard.innerHTML = '<h3>Sprint</h3><div class="crm-sprint-grid"><div class="crm-sprint-metric"><b>' + st.sprints + '</b><span>Sprints hoy</span></div><div class="crm-sprint-metric"><b>' + st.minutes + '</b><span>Min llamados</span></div><div class="crm-sprint-metric"><b>' + st.breaks + '</b><span>Descansos</span></div></div><div class="crm-sprint-log"><b>Estado:</b> ' + status + (st.items.length ? '<br><b>Registro:</b> ' + st.items.join(' · ') : '') + '</div>';
    let report = $('crm-daily-report-card'); if (!report) { report = document.createElement('div'); report.id = 'crm-daily-report-card'; }
    if (report.parentElement !== sc || report !== sc.lastElementChild) sc.appendChild(report);
    if (!report.dataset.ready) { report.dataset.ready = '1'; report.innerHTML = '<div class="crm-report-head"><h3>Informe diario</h3><button class="crm-report-copy secondary" id="crm-refresh-report">Actualizar</button></div><div class="crm-report-block"><div class="crm-report-title">Agendamientos</div><div class="crm-report-pre" id="crm-report-block1">Agendamientos\nCargando...</div><div class="crm-report-actions"><button class="crm-report-copy" id="crm-copy-block1">Copiar</button></div></div><div class="crm-report-block"><div class="crm-report-title">Reporte</div><div class="crm-report-pre" id="crm-report-block2">Reporte\nCargando...</div><div class="crm-report-actions"><button class="crm-report-copy" id="crm-copy-block2">Copiar</button></div></div>'; }
    const b1 = $('crm-report-block1'), b2 = $('crm-report-block2'); if (b1 && block1 && b1.textContent !== block1) b1.textContent = block1; if (b2 && block2 && b2.textContent !== block2) b2.textContent = block2;
    const c1 = $('crm-copy-block1'), c2 = $('crm-copy-block2'), rf = $('crm-refresh-report'); if (c1) c1.onclick = () => copyText(block1 || (b1 ? b1.textContent : '')); if (c2) c2.onclick = () => copyText(block2 || (b2 ? b2.textContent : '')); if (rf) rf.onclick = async () => { await loadReport(true); mountStats(); };
    loadReport(false).then(() => { const x1 = $('crm-report-block1'), x2 = $('crm-report-block2'); if (x1 && block1) x1.textContent = block1; if (x2 && block2) x2.textContent = block2; });
  }

  function update() {
    addStyles();
    const s = load(); if (s.active && !s.active.paused && Date.now() >= s.active.endAt) { finishPhase(s); return; }
    const chip = ensureChip(); if (chip) { const r = remaining(s), warn = !!(s.active && !s.active.paused && r <= 5 * 60 * 1000); const mode = s.active ? (s.active.paused ? 'paused' : (warn ? 'warn' : 'running')) : 'idle'; chip.classList.remove('idle', 'paused', 'warn', 'running'); chip.classList.add(mode); const txt = $('crm-sprint-chip-txt'); if (txt) txt.textContent = s.active ? ((s.active.paused ? 'Pausa ' : (s.active.mode === 'work' ? 'Sprint ' : 'Descanso ')) + fmt(r)) : 'Sprint'; }
    const st = sprintStats(s), time = $('crm-sprint-time'), sub = $('crm-sprint-sub'), mini = $('crm-sprint-mini-stats'), pause = $('crm-sprint-pause'); if (time) time.textContent = s.active ? fmt(remaining(s)) : fmt((s.workMin || 20) * 60000); if (sub) sub.textContent = s.active ? (s.active.paused ? 'Sprint en pausa' : (s.active.mode === 'work' ? 'Sprint en curso' : 'Descanso en curso')) : (s.workMin + ' minutos de llamados + ' + s.breakMin + ' de descanso'); if (mini) mini.textContent = 'Hoy: ' + st.sprints + ' sprints · ' + st.minutes + ' min llamados · ' + st.breaks + ' descansos'; if (pause) pause.textContent = s.active && s.active.paused ? 'Reanudar' : 'Pausar'; mountSettings(); mountStats();
  }

  function boot() { update(); if (timer) clearInterval(timer); timer = setInterval(update, 1000); document.addEventListener('click', () => setTimeout(update, 80), true); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
})();
