(() => {
  'use strict';
  const KEY = 'crm_sprint_v104';
  let timer = null;

  const $ = (id) => document.getElementById(id);
  const today = () => new Date().toISOString().slice(0, 10);
  const base = () => ({ workMin: 20, breakMin: 5, logs: [], active: null });
  const load = () => { try { return Object.assign(base(), JSON.parse(localStorage.getItem(KEY) || '{}')); } catch (e) { return base(); } };
  const save = (s) => { try { localStorage.setItem(KEY, JSON.stringify(s)); } catch (e) {} };
  const remaining = (s) => !s.active ? 0 : Math.max(0, s.active.paused ? Number(s.active.remainingMs || 0) : Number(s.active.endAt || 0) - Date.now());
  const fmt = (ms) => { const t = Math.ceil(Math.max(0, ms) / 1000); return String(Math.floor(t / 60)).padStart(2, '0') + ':' + String(t % 60).padStart(2, '0'); };

  function sbClient() {
    try { if (typeof sb !== 'undefined' && sb) return sb; } catch (e) {}
    try {
      if (window.supabase && typeof SUPABASE_URL !== 'undefined' && typeof SUPABASE_ANON_KEY !== 'undefined') {
        return window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
      }
    } catch (e) {}
    return null;
  }

  function toast(msg) {
    try {
      if (typeof window.toast === 'function') { window.toast(msg); return; }
    } catch (e) {}
    try {
      document.querySelectorAll('.crm-sprint-toast').forEach(x => x.remove());
      const t = document.createElement('div');
      t.className = 'crm-sprint-toast';
      t.textContent = msg;
      document.body.appendChild(t);
      setTimeout(() => t.remove(), 2600);
    } catch (e) {}
  }

  function addStyles() {
    if ($('crm-sprint-v104-style')) return;
    const css = document.createElement('style');
    css.id = 'crm-sprint-v104-style';
    css.textContent = `
      .app:not(.crm-authenticated) .bottom-nav{display:none!important}
      #login-msg{white-space:pre-wrap;line-height:1.35}
      #crm-sprint-chip{height:38px;border-radius:19px;font-weight:800;font-size:12.5px;padding:0 11px;display:flex;align-items:center;gap:6px;white-space:nowrap;background:var(--primary-container)!important;color:var(--on-primary-container)!important;border:1px solid var(--outline)!important}
      #crm-sprint-chip.running{background:#166534!important;color:#fff!important;border-color:#166534!important;box-shadow:0 6px 16px rgba(15,23,42,.14)!important}
      #crm-sprint-chip.warn{background:#b91c1c!important;color:#fff!important;border-color:#b91c1c!important;box-shadow:0 6px 16px rgba(15,23,42,.14)!important}
      #crm-sprint-chip.paused{background:#64748b!important;color:#fff!important;border-color:#64748b!important;box-shadow:0 6px 16px rgba(15,23,42,.14)!important}
      .crm-sprint-panel{position:fixed;inset:0;background:rgba(15,23,42,.36);z-index:9999;display:none;align-items:flex-end;justify-content:center}.crm-sprint-panel.on{display:flex}
      .crm-sprint-card{width:100%;max-width:520px;background:var(--surface);border-radius:26px 26px 0 0;padding:22px 20px calc(22px + env(safe-area-inset-bottom));box-shadow:0 -18px 45px rgba(15,23,42,.24);color:var(--on-surface)}
      .crm-sprint-card h3{margin:0 0 10px;font-size:22px;color:var(--on-surface)}.crm-sprint-time{font-size:42px;font-weight:900;letter-spacing:-.04em;margin:8px 0;color:var(--on-surface)}.crm-sprint-muted{color:var(--muted,var(--on-surface-variant));font-size:14px;line-height:1.35}.crm-sprint-row{display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin-top:14px}.crm-sprint-btn{border:0;border-radius:18px;background:#111827;color:#fff;font-weight:800;padding:13px 16px}.crm-sprint-btn.secondary{background:var(--surface-container);color:var(--on-surface)}.crm-sprint-btn.danger{background:#b91c1c}.crm-sprint-input{width:72px;border:1px solid var(--outline);border-radius:14px;padding:10px 11px;font-weight:800;background:var(--surface);color:var(--on-surface)}
      .crm-sprint-toast{position:fixed;left:20px;right:20px;bottom:calc(86px + env(safe-area-inset-bottom));z-index:10000;background:#111827;color:#fff;border-radius:18px;padding:14px 16px;text-align:center;font-weight:800;box-shadow:0 12px 28px rgba(15,23,42,.22)}
      #crm-sprint-settings{padding:12px 2px 14px;border-top:1px solid var(--outline-variant)}#crm-sprint-settings .crm-sprint-row{margin-top:8px}
      @media(max-width:430px){#crm-sprint-chip{font-size:11.5px;padding:0 9px}.topbar{gap:8px!important}}
    `;
    document.head.appendChild(css);
  }

  function syncAuthChrome() {
    const app = $('app');
    const main = $('main');
    if (!app || !main) return;
    app.classList.toggle('crm-authenticated', !main.classList.contains('hidden'));
  }

  function hardenLogin() {
    const loginScreen = $('login-screen');
    if (!loginScreen) return;
    const btn = loginScreen.querySelector('button.filled-btn');
    const email = $('email');
    const pass = $('password');
    const msg = $('login-msg');
    if (!btn || btn.dataset.crmLoginFixed === '1') return;
    btn.dataset.crmLoginFixed = '1';
    btn.type = 'button';

    async function robustLogin(ev) {
      try { ev && ev.preventDefault && ev.preventDefault(); } catch (e) {}
      const client = sbClient();
      if (!client) {
        if (msg) msg.textContent = 'No se pudo inicializar Supabase. Recarga la página.';
        toast('Supabase no inicializó');
        return;
      }
      const mail = (email && email.value || '').trim();
      const pwd = pass && pass.value || '';
      if (!mail || !pwd) {
        if (msg) msg.textContent = 'Falta correo o contraseña.';
        return;
      }
      btn.disabled = true;
      const old = btn.textContent;
      btn.textContent = 'Entrando…';
      if (msg) msg.textContent = 'Validando acceso…';
      try {
        const { data, error } = await client.auth.signInWithPassword({ email: mail, password: pwd });
        if (error) throw error;
        try { if (typeof user !== 'undefined') user = data.user; } catch (e) {}
        if (msg) msg.textContent = 'Acceso correcto. Cargando contactos…';
        if (typeof enterApp === 'function') await enterApp();
        else {
          loginScreen.classList.add('hidden');
          const main = $('main');
          if (main) main.classList.remove('hidden');
        }
        syncAuthChrome();
        updateSprint();
      } catch (e) {
        const text = e && e.message ? e.message : String(e || 'Error desconocido');
        if (msg) msg.textContent = text;
        toast('No se pudo entrar: ' + text);
      } finally {
        btn.disabled = false;
        btn.textContent = old || 'Entrar';
      }
    }

    btn.addEventListener('click', robustLogin, true);
    if (pass) pass.addEventListener('keydown', e => { if (e.key === 'Enter') robustLogin(e); });
    try { window.login = robustLogin; } catch (e) {}
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

  function startSprint() {
    const s = load();
    const now = Date.now();
    s.active = { mode: 'work', startedAt: now, endAt: now + Math.max(1, Number(s.workMin || 20)) * 60000, paused: false, remainingMs: null };
    save(s);
    toast('Sprint iniciado');
    updateSprint();
  }

  function pauseResume() {
    const s = load();
    if (!s.active) return;
    if (s.active.paused) {
      const r = Math.max(1000, Number(s.active.remainingMs || 0));
      s.active.paused = false;
      s.active.endAt = Date.now() + r;
      s.active.remainingMs = null;
      toast('Sprint reanudado');
    } else {
      s.active.remainingMs = remaining(s);
      s.active.paused = true;
      toast('Sprint en pausa');
    }
    save(s);
    updateSprint();
  }

  function restartSprint() {
    const s = load();
    const now = Date.now();
    s.active = { mode: 'work', startedAt: now, endAt: now + Math.max(1, Number(s.workMin || 20)) * 60000, paused: false, remainingMs: null };
    save(s);
    toast('Sprint reiniciado');
    updateSprint();
  }

  function stopSprint() {
    const s = load();
    if (s.active) {
      s.logs.push({ date: today(), type: 'cancelled', mode: s.active.mode, ts: Date.now() });
      s.active = null;
      save(s);
      toast('Sprint detenido');
    }
    closePanel();
    updateSprint();
  }

  function finishPhase(s) {
    if (!s.active || s.active.paused) return;
    if (s.active.mode === 'work') {
      s.logs.push({ date: today(), type: 'work_complete', minutes: Number(s.workMin || 20), ts: Date.now() });
      s.active = { mode: 'break', startedAt: Date.now(), endAt: Date.now() + Math.max(1, Number(s.breakMin || 5)) * 60000, paused: false, remainingMs: null };
      save(s);
      toast('Sprint completo. Descanso');
    } else {
      s.logs.push({ date: today(), type: 'break_complete', minutes: Number(s.breakMin || 5), ts: Date.now() });
      s.active = null;
      save(s);
      toast('Descanso terminado');
    }
    updateSprint();
  }

  function sprintStats(s) {
    let sprints = 0, breaks = 0, minutes = 0;
    (s.logs || []).forEach(x => {
      if (x.date !== today()) return;
      if (x.type === 'work_complete') { sprints++; minutes += Number(x.minutes || 0); }
      if (x.type === 'break_complete') breaks++;
    });
    return { sprints, breaks, minutes };
  }

  function panel() {
    let p = $('crm-sprint-panel');
    if (p) return p;
    p = document.createElement('div');
    p.id = 'crm-sprint-panel';
    p.className = 'crm-sprint-panel';
    p.innerHTML = '<div class="crm-sprint-card"><h3>Sprint de llamados</h3><div class="crm-sprint-muted" id="crm-sprint-sub"></div><div class="crm-sprint-time" id="crm-sprint-time">20:00</div><div class="crm-sprint-muted" id="crm-sprint-mini"></div><div class="crm-sprint-row"><button class="crm-sprint-btn" id="crm-sprint-pause">Pausar</button><button class="crm-sprint-btn secondary" id="crm-sprint-restart">Reiniciar</button><button class="crm-sprint-btn danger" id="crm-sprint-stop">Detener</button><button class="crm-sprint-btn secondary" id="crm-sprint-close">Cerrar</button></div></div>';
    document.body.appendChild(p);
    p.onclick = e => { if (e.target === p) closePanel(); };
    $('crm-sprint-pause').onclick = pauseResume;
    $('crm-sprint-restart').onclick = restartSprint;
    $('crm-sprint-stop').onclick = stopSprint;
    $('crm-sprint-close').onclick = closePanel;
    return p;
  }
  function openPanel() { panel().classList.add('on'); updateSprint(); }
  function closePanel() { const p = $('crm-sprint-panel'); if (p) p.classList.remove('on'); }

  function mountSettings() {
    const body = document.querySelector('.settings-body');
    if (!body || $('crm-sprint-settings')) return;
    const s = load();
    const el = document.createElement('div');
    el.id = 'crm-sprint-settings';
    el.innerHTML = '<label class="settings-label">Sprint</label><div class="crm-sprint-row"><label class="settings-label" style="margin:0;text-transform:none;letter-spacing:0">Llamados <input id="crm-sprint-work" class="crm-sprint-input" type="number" min="1" max="180" value="' + s.workMin + '"></label><label class="settings-label" style="margin:0;text-transform:none;letter-spacing:0">Descanso <input id="crm-sprint-break" class="crm-sprint-input" type="number" min="1" max="60" value="' + s.breakMin + '"></label></div><div class="crm-sprint-row"><button class="crm-sprint-btn" id="crm-sprint-start-settings">Iniciar</button><button class="crm-sprint-btn secondary" id="crm-sprint-save-settings">Guardar</button></div>';
    const version = $('crm-version-section');
    body.insertBefore(el, version ? version.nextSibling : body.firstChild);
    $('crm-sprint-save-settings').onclick = () => {
      const n = load();
      n.workMin = Math.max(1, Number($('crm-sprint-work').value || 20));
      n.breakMin = Math.max(1, Number($('crm-sprint-break').value || 5));
      save(n);
      toast('Sprint configurado');
      updateSprint();
    };
    $('crm-sprint-start-settings').onclick = startSprint;
  }

  function updateSprint() {
    addStyles();
    syncAuthChrome();
    hardenLogin();
    mountSettings();
    const app = $('app');
    const main = $('main');
    if (!app || !main || main.classList.contains('hidden')) return;
    const s = load();
    if (s.active && !s.active.paused && Date.now() >= s.active.endAt) { finishPhase(s); return; }
    const chip = ensureChip();
    if (chip) {
      const r = remaining(s);
      chip.classList.remove('running', 'warn', 'paused');
      if (s.active) chip.classList.add(s.active.paused ? 'paused' : (r <= 5 * 60 * 1000 ? 'warn' : 'running'));
      const txt = $('crm-sprint-chip-txt');
      if (txt) txt.textContent = s.active ? ((s.active.paused ? 'Pausa ' : (s.active.mode === 'work' ? 'Sprint ' : 'Descanso ')) + fmt(r)) : 'Sprint';
    }
    const p = $('crm-sprint-panel');
    if (p) {
      const st = sprintStats(s);
      const time = $('crm-sprint-time');
      const sub = $('crm-sprint-sub');
      const mini = $('crm-sprint-mini');
      const pause = $('crm-sprint-pause');
      if (time) time.textContent = s.active ? fmt(remaining(s)) : fmt((s.workMin || 20) * 60000);
      if (sub) sub.textContent = s.active ? (s.active.paused ? 'Sprint en pausa' : (s.active.mode === 'work' ? 'Sprint en curso' : 'Descanso en curso')) : (s.workMin + ' minutos de llamados + ' + s.breakMin + ' de descanso');
      if (mini) mini.textContent = 'Hoy: ' + st.sprints + ' sprints · ' + st.minutes + ' min llamados · ' + st.breaks + ' descansos';
      if (pause) pause.textContent = s.active && s.active.paused ? 'Reanudar' : 'Pausar';
    }
  }

  function boot() {
    addStyles();
    hardenLogin();
    syncAuthChrome();
    updateSprint();
    if (timer) clearInterval(timer);
    timer = setInterval(updateSprint, 1000);
    document.addEventListener('click', () => setTimeout(updateSprint, 80), true);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
