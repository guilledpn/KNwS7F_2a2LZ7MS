(() => {
  const KEY = 'crm_sprint_v1';
  let timer = null;
  let lastStatsHtml = '';
  let lastChipText = '';
  let lastChipMode = '';
  let lastChipWarn = false;
  let dailyReport = null;
  let dailyReportLoading = false;
  let dailyReportDay = '';

  function base() {
    return { workMin: 20, breakMin: 5, logs: [], active: null };
  }

  function load() {
    try { return Object.assign(base(), JSON.parse(localStorage.getItem(KEY) || '{}')); }
    catch (e) { return base(); }
  }

  function save(state) {
    try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {}
  }

  function today() {
    return new Date().toISOString().slice(0, 10);
  }

  function fmt(ms) {
    ms = Math.max(0, ms);
    const t = Math.ceil(ms / 1000);
    const m = Math.floor(t / 60);
    const s = t % 60;
    return String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
  }

  function remaining(state) {
    if (!state.active) return 0;
    if (state.active.paused) return Math.max(0, Number(state.active.remainingMs || 0));
    return Math.max(0, Number(state.active.endAt || 0) - Date.now());
  }

  function dayStats(state) {
    const d = today();
    let sprints = 0, breaks = 0, minutes = 0, cancelled = 0;
    const items = [];
    (state.logs || []).forEach((log) => {
      if (log.date !== d) return;
      if (log.type === 'work_complete') {
        sprints += 1;
        minutes += Number(log.minutes || 0);
        items.push('Sprint ' + sprints + ' · ' + (log.minutes || 0) + ' min');
      } else if (log.type === 'break_complete') {
        breaks += 1;
      } else if (log.type === 'cancelled') {
        cancelled += 1;
        items.push('Cancelado');
      }
    });
    return { sprints, breaks, minutes, cancelled, items: items.slice(-4) };
  }

  function toast(message) {
    try {
      if (navigator.vibrate) navigator.vibrate([120, 60, 120]);
      const old = document.querySelector('.crm-sprint-toast');
      if (old) old.remove();
      const el = document.createElement('div');
      el.className = 'crm-sprint-toast';
      el.textContent = message;
      document.body.appendChild(el);
      setTimeout(() => el.remove(), 2500);
    } catch (e) {}
  }

  function addStyles() {
    if (document.getElementById('crm-sprint-style')) return;
    const style = document.createElement('style');
    style.id = 'crm-sprint-style';
    style.textContent = `
      #crm-sprint-chip{height:38px;border:0;border-radius:19px;background:#166534;color:#fff;font-weight:800;font-size:12.5px;padding:0 11px;display:flex;align-items:center;gap:6px;white-space:nowrap;box-shadow:0 6px 16px rgba(15,23,42,.16)}
      #crm-sprint-chip.warn{background:#ba1a1a}#crm-sprint-chip.paused{background:#475569}#crm-sprint-chip.idle{background:#0f172a}
      .crm-sprint-panel{position:fixed;inset:0;background:rgba(15,23,42,.36);z-index:9999;display:none;align-items:flex-end;justify-content:center}.crm-sprint-panel.on{display:flex}
      .crm-sprint-card{width:100%;max-width:520px;background:#fff;border-radius:26px 26px 0 0;padding:22px 20px calc(22px + env(safe-area-inset-bottom));box-shadow:0 -18px 45px rgba(15,23,42,.24)}
      .crm-sprint-card h3{margin:0 0 8px;font-size:22px}.crm-sprint-time{font-size:42px;font-weight:900;letter-spacing:-.04em;margin:8px 0;color:#0f172a}.crm-sprint-muted{color:#475569;font-size:14px;line-height:1.35}.crm-sprint-row{display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin-top:14px}.crm-sprint-btn{border:0;border-radius:18px;background:#0f172a;color:#fff;font-weight:800;padding:13px 16px}.crm-sprint-btn.secondary{background:#e8eef7;color:#0f172a}.crm-sprint-btn.danger{background:#ba1a1a}.crm-sprint-input{width:72px;border:1px solid #cbd5e1;border-radius:14px;padding:10px 11px;font-weight:800;background:#fff}
      .crm-sprint-toast{position:fixed;left:20px;right:20px;bottom:calc(86px + env(safe-area-inset-bottom));z-index:10000;background:#0f172a;color:#fff;border-radius:18px;padding:14px 16px;text-align:center;font-weight:800;box-shadow:0 12px 28px rgba(15,23,42,.22)}
      #crm-sprint-stats-card,#crm-daily-report-card{background:#fff;border:1px solid rgba(198,208,224,.9);border-radius:24px;margin:0 0 14px;padding:16px;box-shadow:0 1px 3px rgba(15,23,42,.06),0 8px 22px rgba(15,23,42,.04)}#crm-sprint-stats-card h3,#crm-daily-report-card h3{margin:0 0 10px;font-size:18px}.crm-sprint-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}.crm-sprint-metric{background:#f6f9ff;border:1px solid #dbe5f3;border-radius:18px;padding:12px}.crm-sprint-metric b{display:block;font-size:22px;color:#0f172a}.crm-sprint-metric span{font-size:12px;color:#64748b}.crm-sprint-log{margin-top:12px;color:#475569;font-size:13px;line-height:1.35}.crm-report-block{background:#f6f9ff;border:1px solid #dbe5f3;border-radius:18px;padding:12px;margin-top:10px}.crm-report-title{font-weight:900;margin-bottom:8px;color:#0f172a}.crm-report-pre{white-space:pre-wrap;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:12.5px;color:#24324a;background:#fff;border:1px solid #e2e8f0;border-radius:14px;padding:10px;max-height:190px;overflow:auto}.crm-report-actions{display:flex;gap:8px;margin-top:8px;flex-wrap:wrap}.crm-report-copy{border:0;border-radius:14px;background:#0f172a;color:#fff;font-weight:800;padding:10px 12px}.crm-report-copy.secondary{background:#e8eef7;color:#0f172a}
      @media(max-width:430px){#crm-sprint-chip{font-size:11.5px;padding:0 9px}.goal-chip{min-width:auto!important;padding:0 9px!important}.topbar{gap:8px!important}.crm-sprint-grid{grid-template-columns:repeat(2,1fr)}}
    `;
    document.head.appendChild(style);
  }

  function ensureChip() {
    const topbar = document.getElementById('main-topbar');
    if (!topbar) return null;
    let chip = document.getElementById('crm-sprint-chip');
    if (!chip) {
      chip = document.createElement('button');
      chip.id = 'crm-sprint-chip';
      chip.type = 'button';
      chip.innerHTML = '<span id="crm-sprint-chip-txt">Sprint</span>';
      const goal = topbar.querySelector('.goal-chip');
      topbar.insertBefore(chip, goal || topbar.querySelector('.icon-btn') || null);
    }
    chip.onclick = () => {
      const state = load();
      if (state.active) openPanel();
      else startSprint();
    };
    return chip;
  }

  function startSprint() {
    const state = load();
    const now = Date.now();
    state.active = { mode: 'work', startedAt: now, endAt: now + Math.max(1, Number(state.workMin || 20)) * 60000, paused: false, remainingMs: null };
    save(state);
    toast('Sprint iniciado');
    update();
  }

  function pauseOrResumeSprint() {
    const state = load();
    if (!state.active) return;
    if (state.active.paused) {
      const rem = Math.max(1000, Number(state.active.remainingMs || 0));
      state.active.paused = false;
      state.active.endAt = Date.now() + rem;
      state.active.remainingMs = null;
      save(state);
      toast('Sprint reanudado');
    } else {
      state.active.remainingMs = remaining(state);
      state.active.paused = true;
      save(state);
      toast('Sprint en pausa');
    }
    update();
  }

  function restartSprint() {
    const state = load();
    const now = Date.now();
    state.active = { mode: 'work', startedAt: now, endAt: now + Math.max(1, Number(state.workMin || 20)) * 60000, paused: false, remainingMs: null };
    save(state);
    toast('Sprint reiniciado');
    update();
  }

  function stopSprint() {
    const state = load();
    if (state.active) {
      state.logs.push({ date: today(), type: 'cancelled', mode: state.active.mode, ts: Date.now() });
      state.active = null;
      save(state);
      toast('Sprint detenido');
    }
    closePanel();
    update();
  }

  function finishPhase(state) {
    if (!state.active || state.active.paused) return;
    if (state.active.mode === 'work') {
      state.logs.push({ date: today(), type: 'work_complete', minutes: Number(state.workMin || 20), ts: Date.now() });
      state.active = { mode: 'break', startedAt: Date.now(), endAt: Date.now() + Math.max(1, Number(state.breakMin || 5)) * 60000, paused: false, remainingMs: null };
      save(state);
      toast('Sprint completo. Descanso');
    } else {
      state.logs.push({ date: today(), type: 'break_complete', minutes: Number(state.breakMin || 5), ts: Date.now() });
      state.active = null;
      save(state);
      toast('Descanso terminado');
    }
    update();
  }

  function panel() {
    let p = document.getElementById('crm-sprint-panel');
    if (p) return p;
    p = document.createElement('div');
    p.id = 'crm-sprint-panel';
    p.className = 'crm-sprint-panel';
    p.innerHTML = '<div class="crm-sprint-card"><h3>Sprint de llamados</h3><div class="crm-sprint-muted" id="crm-sprint-sub">20 minutos de llamados + 5 de descanso</div><div class="crm-sprint-time" id="crm-sprint-time">20:00</div><div class="crm-sprint-muted" id="crm-sprint-mini-stats"></div><div class="crm-sprint-row"><button class="crm-sprint-btn" id="crm-sprint-pause">Pausar</button><button class="crm-sprint-btn secondary" id="crm-sprint-restart">Reiniciar</button><button class="crm-sprint-btn danger" id="crm-sprint-stop">Detener</button><button class="crm-sprint-btn secondary" id="crm-sprint-close">Cerrar</button></div></div>';
    document.body.appendChild(p);
    p.onclick = (e) => { if (e.target === p) closePanel(); };
    p.querySelector('#crm-sprint-pause').onclick = pauseOrResumeSprint;
    p.querySelector('#crm-sprint-restart').onclick = restartSprint;
    p.querySelector('#crm-sprint-stop').onclick = stopSprint;
    p.querySelector('#crm-sprint-close').onclick = closePanel;
    return p;
  }

  function openPanel() { panel().classList.add('on'); update(); }
  function closePanel() { const p = document.getElementById('crm-sprint-panel'); if (p) p.classList.remove('on'); }

  function getSb() {
    try { return sb || null; } catch (e) { return null; }
  }

  function keyForLabel(label) {
    const s = String(label || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
    if (s === 'agenda') return 'agenda';
    if (s === 'no agenda') return 'no_agenda';
    if (s === 'volver a llamar') return 'volver';
    if (s === 'no contactado') return 'no_contactado';
    if (s === 'invalido') return 'invalido';
    if (s === 'pendiente') return 'pendiente';
    return '';
  }

  function formatRut(r) {
    const s = String(r || '').trim();
    if (!s) return '';
    if (s.includes('-')) return s;
    if (s.length > 1) return s.slice(0, -1) + '-' + s.slice(-1);
    return s;
  }

  async function loadDailyReport(force = false) {
    const d = today();
    if (!force && dailyReport && dailyReportDay === d) return dailyReport;
    if (dailyReportLoading) return dailyReport;
    const client = getSb();
    if (!client) return null;
    dailyReportLoading = true;
    try {
      const { data, error } = await client.from('crm_log').select('work_item_id,contact_id,rut_norm,estado_nuevo,created_at,fecha').gte('fecha', d).lte('fecha', d).order('created_at', { ascending: true });
      if (error) throw error;
      const last = {};
      (data || []).forEach((r) => { if (r.work_item_id) last[r.work_item_id] = r; });
      const vals = Object.values(last);
      const counts = { agenda: 0, no_agenda: 0, volver: 0, no_contactado: 0, invalido: 0, pendiente: 0 };
      vals.forEach((r) => { const k = keyForLabel(r.estado_nuevo); if (k && counts[k] != null) counts[k] += 1; });
      const agendaRows = vals.filter((r) => keyForLabel(r.estado_nuevo) === 'agenda');
      const ids = agendaRows.map((r) => r.work_item_id).filter(Boolean);
      let nameMap = {};
      if (ids.length) {
        const { data: wq } = await client.from('work_queue').select('work_item_id,nombre,rut_norm').in('work_item_id', ids);
        (wq || []).forEach((r) => { nameMap[r.work_item_id] = r; });
      }
      const ag = agendaRows.map((r) => {
        const w = nameMap[r.work_item_id] || {};
        return { nombre: w.nombre || 'Sin nombre', rut: formatRut(w.rut_norm || r.rut_norm || '') };
      }).sort((a, b) => a.nombre.localeCompare(b.nombre, 'es'));
      const total = counts.agenda + counts.no_agenda + counts.volver + counts.no_contactado + counts.invalido;
      const effective = counts.agenda + counts.no_agenda;
      const block1 = 'Agendamientos\n' + (ag.length ? ag.map((x) => '- ' + x.nombre + (x.rut ? ' · ' + x.rut : '')).join('\n') : '- Sin agendamientos');
      const block2 = 'Reporte\nLlamadas totales: ' + total + '\nLlamadas efectivas: ' + effective + '\nAgendan: ' + counts.agenda + '\nNo Agenda: ' + counts.no_agenda;
      dailyReport = { day: d, counts, agendas: ag, block1, block2 };
      dailyReportDay = d;
      return dailyReport;
    } catch (e) {
      dailyReport = { day: d, error: true, block1: 'Agendamientos\n- Error al cargar datos', block2: 'Reporte\nLlamadas totales: 0\nLlamadas efectivas: 0\nAgendan: 0\nNo Agenda: 0' };
      dailyReportDay = d;
      return dailyReport;
    } finally {
      dailyReportLoading = false;
    }
  }

  async function copyText(text) {
    try {
      await navigator.clipboard.writeText(text);
      toast('Copiado');
    } catch (e) {
      toast('No se pudo copiar');
    }
  }

  function mountSettings() {
    const version = document.getElementById('crm-version-section');
    if (!version || document.getElementById('crm-sprint-settings')) return;
    const state = load();
    const el = document.createElement('div');
    el.className = 'settings-section';
    el.id = 'crm-sprint-settings';
    el.innerHTML = '<label class="settings-label">Sprint de llamados</label><div class="settings-note">Configura la duración. Las estadísticas aparecen en Stats.</div><div class="crm-sprint-row"><label class="settings-note">Llamados <input id="crm-sprint-work" class="crm-sprint-input" type="number" min="1" max="180" value="' + state.workMin + '"></label><label class="settings-note">Descanso <input id="crm-sprint-break" class="crm-sprint-input" type="number" min="1" max="60" value="' + state.breakMin + '"></label></div><div class="crm-sprint-row"><button class="crm-sprint-btn" id="crm-sprint-start-settings">Iniciar sprint</button><button class="crm-sprint-btn secondary" id="crm-sprint-save-settings">Guardar</button></div>';
    version.parentNode.insertBefore(el, version);
    el.querySelector('#crm-sprint-save-settings').onclick = () => {
      const next = load();
      next.workMin = Math.max(1, Number(el.querySelector('#crm-sprint-work').value || 20));
      next.breakMin = Math.max(1, Number(el.querySelector('#crm-sprint-break').value || 5));
      save(next);
      toast('Sprint configurado');
      update();
    };
    el.querySelector('#crm-sprint-start-settings').onclick = startSprint;
  }

  function mountStats() {
    const statsScroll = document.getElementById('stats-scroll');
    if (!statsScroll) return;
    const statsScreen = document.getElementById('screen-stats');
    if (statsScreen && !statsScreen.classList.contains('on')) return;
    let card = document.getElementById('crm-sprint-stats-card');
    if (!card) {
      card = document.createElement('div');
      card.id = 'crm-sprint-stats-card';
      statsScroll.insertBefore(card, statsScroll.firstChild);
    }
    const state = load();
    const s = dayStats(state);
    const status = state.active ? ((state.active.paused ? 'En pausa · ' : (state.active.mode === 'work' ? 'Sprint en curso · ' : 'Descanso en curso · ')) + fmt(remaining(state))) : 'Sin sprint activo';
    const html = '<h3>Sprint de llamados</h3><div class="crm-sprint-grid"><div class="crm-sprint-metric"><b>' + s.sprints + '</b><span>Sprints hoy</span></div><div class="crm-sprint-metric"><b>' + s.minutes + '</b><span>Min llamados</span></div><div class="crm-sprint-metric"><b>' + s.breaks + '</b><span>Descansos</span></div></div><div class="crm-sprint-log"><b>Estado:</b> ' + status + (s.items.length ? '<br><b>Registro:</b> ' + s.items.join(' · ') : '') + '</div>';
    if (html !== lastStatsHtml) {
      lastStatsHtml = html;
      card.innerHTML = html;
    }

    let reportCard = document.getElementById('crm-daily-report-card');
    if (!reportCard) {
      reportCard = document.createElement('div');
      reportCard.id = 'crm-daily-report-card';
      card.insertAdjacentElement('afterend', reportCard);
    }
    const rep = dailyReport;
    const block1 = rep ? rep.block1 : 'Agendamientos\nCargando...';
    const block2 = rep ? rep.block2 : 'Reporte\nCargando...';
    reportCard.innerHTML = '<h3>Informe diario</h3><div class="crm-report-block"><div class="crm-report-title">Bloque 1: Agendamientos</div><div class="crm-report-pre" id="crm-report-block1"></div><div class="crm-report-actions"><button class="crm-report-copy" id="crm-copy-block1">Copiar Bloque 1</button></div></div><div class="crm-report-block"><div class="crm-report-title">Bloque 2: Reporte</div><div class="crm-report-pre" id="crm-report-block2"></div><div class="crm-report-actions"><button class="crm-report-copy" id="crm-copy-block2">Copiar Bloque 2</button><button class="crm-report-copy secondary" id="crm-refresh-report">Actualizar</button></div></div>';
    reportCard.querySelector('#crm-report-block1').textContent = block1;
    reportCard.querySelector('#crm-report-block2').textContent = block2;
    reportCard.querySelector('#crm-copy-block1').onclick = () => copyText((dailyReport || {}).block1 || block1);
    reportCard.querySelector('#crm-copy-block2').onclick = () => copyText((dailyReport || {}).block2 || block2);
    reportCard.querySelector('#crm-refresh-report').onclick = async () => { await loadDailyReport(true); lastStatsHtml = ''; update(); };
    if (!rep && !dailyReportLoading) loadDailyReport(false).then(() => { lastStatsHtml = ''; update(); });
  }

  function update() {
    addStyles();
    const state = load();
    if (state.active && !state.active.paused && Date.now() >= state.active.endAt) {
      finishPhase(state);
      return;
    }
    const chip = ensureChip();
    if (chip) {
      const rem = remaining(state);
      const warn = !!(state.active && !state.active.paused && rem <= 5 * 60 * 1000);
      const mode = state.active ? (state.active.paused ? 'paused' : (warn ? 'warn' : 'running')) : 'idle';
      const label = state.active ? ((state.active.paused ? 'Pausa ' : (state.active.mode === 'work' ? 'Sprint ' : 'Descanso ')) + fmt(rem)) : 'Sprint';
      if (mode !== lastChipMode || warn !== lastChipWarn) {
        chip.classList.remove('idle', 'paused', 'warn');
        if (mode === 'idle') chip.classList.add('idle');
        if (mode === 'paused') chip.classList.add('paused');
        if (mode === 'warn') chip.classList.add('warn');
        lastChipMode = mode;
        lastChipWarn = warn;
      }
      if (label !== lastChipText) {
        lastChipText = label;
        const text = document.getElementById('crm-sprint-chip-txt');
        if (text) text.textContent = label;
      }
    }
    const s = dayStats(state);
    const time = document.getElementById('crm-sprint-time');
    const sub = document.getElementById('crm-sprint-sub');
    const mini = document.getElementById('crm-sprint-mini-stats');
    const pauseBtn = document.getElementById('crm-sprint-pause');
    if (time) time.textContent = state.active ? fmt(remaining(state)) : fmt((state.workMin || 20) * 60000);
    if (sub) sub.textContent = state.active ? (state.active.paused ? 'Sprint en pausa' : (state.active.mode === 'work' ? 'Sprint en curso' : 'Descanso en curso')) : (state.workMin + ' minutos de llamados + ' + state.breakMin + ' de descanso');
    if (mini) mini.textContent = 'Hoy: ' + s.sprints + ' sprints · ' + s.minutes + ' min llamados · ' + s.breaks + ' descansos';
    if (pauseBtn) pauseBtn.textContent = state.active && state.active.paused ? 'Reanudar' : 'Pausar';
    mountSettings();
    mountStats();
  }

  function boot() {
    update();
    if (timer) clearInterval(timer);
    timer = setInterval(update, 1000);
    document.addEventListener('click', () => setTimeout(update, 80), true);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
