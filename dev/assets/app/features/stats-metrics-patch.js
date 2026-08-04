(function installStatsMetricsPatch(global) {
  'use strict';

  const PATCH_ID = 'LCD-20260804-01';
  let installed = false;

  function byId(id) {
    return document.getElementById(id);
  }

  function number(value) {
    return Number(value || 0);
  }

  function format(value) {
    return number(value).toLocaleString('es-CL');
  }

  function decimal(value) {
    return number(value).toLocaleString('es-CL', { maximumFractionDigits: 2 });
  }

  function currency(value) {
    return number(value).toLocaleString('es-CL', {
      style: 'currency',
      currency: 'CLP',
      maximumFractionDigits: 0
    });
  }

  function percent(value) {
    return value == null
      ? '–'
      : Number(value).toLocaleString('es-CL', { maximumFractionDigits: 1 }) + '%';
  }

  function breakdownValue(breakdown, label) {
    return Number((breakdown || {})[label] || 0);
  }

  function agendaLine(row) {
    const name = String(row?.nombre || 'Sin nombre');
    const rut = String(row?.rut || row?.rut_norm || '').trim();
    return '- ' + name + (rut ? ' · ' + rut : '');
  }

  async function patchedLoadDailyReport() {
    const blockAgendas = byId('crm-report-block1');
    const blockReport = byId('crm-report-block2');
    if (!blockAgendas || !blockReport || !global.AppDev?.supabase) return;

    try {
      const client = global.AppDev.supabase.getClient();
      const { data, error } = await client.rpc('get_daily_management_report_v1', { p_date: null });
      if (error) throw error;

      const agendas = Array.isArray(data?.agenda_rows) ? data.agenda_rows : [];
      const breakdown = data?.final_state_breakdown || {};

      blockAgendas.textContent =
        'Agendamientos\n' +
        (agendas.length ? agendas.map(agendaLine).join('\n') : '- Sin agendamientos');

      blockReport.textContent = [
        'Reporte',
        'Contactos trabajados: ' + format(data?.worked_contacts),
        'Llamadas efectivas: ' + format(data?.effective_calls),
        'Agendan: ' + format(data?.agendas),
        'No agenda: ' + format(data?.no_agenda),
        'No contactado: ' + format(breakdownValue(breakdown, 'No contactado')),
        'Volver a llamar: ' + format(breakdownValue(breakdown, 'Volver a llamar')),
        'Contacto inválido: ' + format(breakdownValue(breakdown, 'Contacto Inválido')),
        'Pendiente: ' + format(breakdownValue(breakdown, 'Pendiente'))
      ].join('\n');
    } catch (error) {
      blockAgendas.textContent = 'Agendamientos\n- Datos no disponibles';
      blockReport.textContent = 'Reporte\nDatos no disponibles por error de carga.';
      console.error('Stats metrics patch report error', error);
    }
  }

  async function patchedRefreshGoal() {
    let done = 0;
    let goal = 0;

    try {
      const client = global.AppDev.supabase.getClient();
      const { data, error } = await client.rpc('get_daily_management_report_v1', { p_date: null });
      if (error) throw error;
      done = number(data?.agendas);
      goal = await dailyGoal(currentGoalMonth());
    } catch (error) {
      console.error('Stats metrics patch goal error', error);
    }

    const text = `${done}/${goal || 0}`;
    const top = byId('goal-mini-top');
    const topText = byId('goal-chip-text');
    if (top) top.innerHTML = ring(done, goal || 1, 22);
    if (topText) topText.textContent = text;

    const detail = byId('goal-mini-detail');
    const detailText = byId('goal-chip-detail');
    if (detail) detail.innerHTML = ring(done, goal || 1, 20);
    if (detailText) detailText.textContent = text;
  }

  async function patchedRenderStats() {
    const scroll = byId('stats-scroll');
    if (!scroll) return;

    const client = global.AppDev?.supabase?.getClient?.();
    if (!client) {
      scroll.innerHTML = '<div class="empty">Configura Supabase para ver estadísticas</div>';
      return;
    }

    scroll.innerHTML = '<div class="empty">Cargando estadísticas…</div>';

    try {
      const { data, error } = await client.rpc('get_stats_cockpit_v1');
      if (error) throw error;

      const cockpit = data || {};
      const goal = cockpit.goal || {};
      const month = cockpit.month || {};
      const story = cockpit.month_story || {};
      const periods = cockpit.periods || {};
      const periodKey = stats === 'hora'
        ? 'last_hour'
        : (stats === 'semana' ? 'week' : (stats === 'mes' ? 'month' : 'today'));
      const selected = periods[periodKey] || periods.today || {};
      const today = periods.today || {};
      const nextAgenda = cockpit.next_agenda || {};

      const target = number(goal.monthly_agendas);
      const normalDaily = number(goal.normal_daily_agendas);
      const todayTarget = number(goal.today_target_agendas);
      const actual = number(month.actual_agendas);
      const todayAgendas = number(today.agendas);
      const remaining = number(month.remaining_agendas);
      const expectedToday = number(month.expected_through_today);
      const gap = number(month.gap_to_pace);
      const daysLeft = number(month.active_days_left_including_today);
      const needed = number(month.needed_daily_to_finish);
      const recommended = number(month.recommended_today_agendas);
      const projectedCurrent = number(month.projected_end_at_current_pace);
      const projectedNormal = number(month.projected_end_if_normal_from_now);
      const cnsPerAgenda = number(goal.estimated_cns_per_agenda);
      const clpPerAgenda = number(goal.estimated_clp_per_agenda);
      const targetCns = number(goal.target_expected_cns);
      const targetClp = number(goal.target_expected_clp);
      const progress = target ? Math.min(100, Math.round(actual / target * 100)) : 0;
      const missionPct = recommended
        ? Math.min(100, Math.round(todayAgendas / recommended * 100))
        : 0;
      const generated = cockpit.generated_at ? new Date(cockpit.generated_at) : new Date();
      const updated = generated.toLocaleTimeString('es-CL', {
        hour: '2-digit',
        minute: '2-digit'
      });

      const missionValue = recommended
        ? format(todayAgendas) + ' / ' + format(recommended)
        : format(todayAgendas) + ' hoy';
      const missionNote = target <= 0
        ? 'Define la Meta Mensual en Ajustes para activar el ritmo.'
        : (recommended > todayTarget
          ? 'Meta fijada en Ajustes: ' + format(todayTarget) + ' hoy. Recuperación sugerida: ' + format(recommended) + ' para sostener la meta mensual.'
          : 'Meta fijada en Ajustes: ' + format(todayTarget) + ' hoy. La misión coincide con el ritmo mensual.');
      const paceSentence = remaining <= 0
        ? 'Meta mensual cumplida. Mantén la calidad y el registro correcto.'
        : (gap < 0
          ? 'Vas ' + format(Math.abs(gap)) + ' bajo la línea ideal de ' + format(expectedToday) + ' agendas a esta fecha.'
          : 'Vas ' + format(gap) + ' sobre la línea ideal de ' + format(expectedToday) + ' agendas a esta fecha.');

      const sub = byId('stats-sub');
      if (sub) sub.textContent = (selected.label || 'Hoy') + ' · actualizado ' + updated;

      let html = '<div class="metric-grid">';
      html += '<div class="metric full"><div class="metric-label">Misión útil de hoy</div><div class="metric-number">' + missionValue + '</div><div class="progress"><div class="fill" style="width:' + missionPct + '%"></div></div><div class="metric-note">' + missionNote + '</div><div class="native-mini">' + miniBlocks(recommended) + '</div><div class="metric-note" style="margin-top:12px"><b>Próxima agenda:</b> +' + decimal(nextAgenda.expected_cns || cnsPerAgenda) + ' CNS / +' + currency(nextAgenda.expected_clp || clpPerAgenda) + ' esperados.</div></div>';
      html += '<div class="metric full"><div class="metric-label">Pulso esperado · ' + (selected.label || 'Hoy') + '</div><div class="metric-number">' + currency(selected.expected_clp) + '</div><div class="metric-note">' + format(selected.agendas) + ' agenda(s) = ' + decimal(selected.expected_cns) + ' CNS esperados. Estimación motivacional; no es producción reconocida ni ingreso devengado.</div></div>';
      html += '<div class="metric"><div class="metric-label">Trabajados</div><div class="metric-number">' + format(selected.worked_contacts) + '</div><div class="metric-note">Personas con cambio real de estado.</div></div>';
      html += '<div class="metric"><div class="metric-label">Llamadas efectivas</div><div class="metric-number">' + format(selected.effective_calls) + '</div><div class="metric-note">' + format(selected.agendas) + ' agendan · ' + format(selected.no_agenda) + ' no agendan.</div></div>';
      html += '<div class="metric"><div class="metric-label">Agendamientos</div><div class="metric-number">' + format(selected.agendas) + '</div><div class="metric-note">Resultado final Agenda en la ventana.</div></div>';
      html += '<div class="metric"><div class="metric-label">Conversión efectiva</div><div class="metric-number">' + percent(selected.effective_conversion_rate) + '</div><div class="metric-note">Agendamientos / llamadas efectivas.</div></div></div>';

      html += '<div class="status-list native-story"><div class="status-list-title">Ritmo mensual</div><div class="metric-note" style="padding:14px 18px 0">' + paceSentence + '</div>' + chartMonth(story, projectedCurrent) + '</div>';
      html += '<div class="native-scenarios">';
      html += '<div class="native-scenario"><div><b>Si sigues igual</b><div class="metric-note">' + currency(projectedCurrent * clpPerAgenda) + ' esperados.</div></div><strong>' + format(projectedCurrent) + '/' + format(target) + '</strong></div>';
      html += '<div class="native-scenario"><div><b>Si haces lo normal</b><div class="metric-note">' + format(normalDaily) + ' por día útil · ' + currency(projectedNormal * clpPerAgenda) + ' esperados.</div></div><strong>' + format(projectedNormal) + '/' + format(target) + '</strong></div>';
      html += '<div class="native-scenario"><div><b>Para llegar</b><div class="metric-note">' + format(daysLeft) + ' días útiles · ' + decimal(needed * cnsPerAgenda) + ' CNS/día.</div></div><strong>' + format(needed) + '/día</strong></div></div>';

      html += '<div class="metric-grid"><div class="metric full"><div class="metric-label">Meta del mes desde Ajustes</div><div class="metric-number">' + format(actual) + ' / ' + format(target) + '</div><div class="progress"><div class="fill" style="width:' + progress + '%"></div></div><div class="metric-note">' + decimal(month.actual_expected_cns) + ' / ' + decimal(targetCns) + ' CNS esperados · ' + currency(month.actual_expected_clp) + ' / ' + currency(targetClp) + '. Faltan ' + format(remaining) + ' agendas.</div></div></div>';

      html += reportCardSkeleton();
      scroll.innerHTML = html;
      await patchedLoadDailyReport();
    } catch (error) {
      scroll.innerHTML =
        '<div class="empty">Datos estadísticos no disponibles<br>' +
        String(error?.message || error) +
        '</div>';
      console.error('Stats metrics patch render error', error);
    }
  }

  function install() {
    if (installed) return;
    if (
      typeof global.renderStats !== 'function' ||
      typeof global.refreshGoal !== 'function' ||
      typeof global.reportCardSkeleton !== 'function'
    ) {
      setTimeout(install, 50);
      return;
    }

    global.renderStats = patchedRenderStats;
    global.loadDailyReport = patchedLoadDailyReport;
    global.refreshGoal = patchedRefreshGoal;
    global.CRM_STATS_METRICS_PATCH = PATCH_ID;
    installed = true;

    setTimeout(() => {
      patchedRefreshGoal();
      if (typeof currentScreen !== 'undefined' && currentScreen === 'stats') {
        patchedRenderStats();
      }
    }, 0);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', install, { once: true });
  } else {
    install();
  }
})(window);
