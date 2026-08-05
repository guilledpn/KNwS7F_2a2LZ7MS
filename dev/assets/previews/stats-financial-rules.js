(function bootstrapStatsFinancialRules(global) {
  'use strict';

  const number = value => Number.isFinite(Number(value)) ? Number(value) : 0;

  function plannedRows(data) {
    let previous = 0;
    return (data?.month_story?.series || []).map(raw => {
      const expected = number(raw.expected_cumulative);
      const planned = Math.max(0, expected - previous);
      previous = expected;
      return {
        ...raw,
        day: String(raw.day),
        planned,
        daily: number(raw.daily_agendas)
      };
    });
  }

  function targetForWeek(data) {
    const start = String(data?.month?.week_start || '');
    const end = String(data?.month?.week_end || '');
    return plannedRows(data)
      .filter(row => row.day >= start && row.day <= end)
      .reduce((sum, row) => sum + row.planned, 0);
  }

  function streakForMonth(data) {
    const monthly = number(data?.goal?.monthly_agendas);
    if (monthly <= 0) return { count: 0, enabled: false };

    const today = String(data?.month_story?.today || '');
    const todayTarget = number(data?.goal?.today_target_agendas);
    const active = plannedRows(data)
      .map(row => ({ ...row, target: row.day === today ? todayTarget : row.planned }))
      .filter(row => row.is_workday && row.target > 0 && row.day <= today);

    let index = active.length - 1;
    if (index >= 0 && active[index].day === today && active[index].daily < active[index].target) {
      index -= 1;
    }

    let count = 0;
    for (let cursor = index; cursor >= 0; cursor -= 1) {
      if (active[cursor].daily >= active[cursor].target) count += 1;
      else break;
    }
    return { count, enabled: true };
  }

  function rhythmState(data) {
    const monthly = number(data?.goal?.monthly_agendas);
    const actual = number(data?.month?.actual_agendas);
    const gap = number(data?.month?.gap_to_pace);
    const remaining = number(data?.month?.remaining_agendas);
    const normal = number(data?.goal?.normal_daily_agendas);
    const needed = number(data?.month?.needed_daily_to_finish);

    if (monthly <= 0) {
      return {
        key: 'none',
        title: 'Sin meta mensual',
        color: '#6d788b',
        message: 'La vista mantiene los resultados reales, pero no calcula ritmo, brecha ni racha hasta que configures una meta.',
        gap: 0
      };
    }
    if (remaining <= 0) {
      return {
        key: 'complete',
        title: 'Meta mensual cumplida',
        color: '#14804f',
        message: 'Ya alcanzaste la Meta Mensual. El foco ahora es sostener calidad y registrar correctamente cada gestión.',
        gap: actual - monthly
      };
    }
    if (normal > 0 && gap >= normal) {
      return {
        key: 'spectacular',
        title: 'Vas espectacular',
        color: '#6846cc',
        message: 'Llevas al menos un día completo de ventaja sobre el ritmo ideal del mes.',
        gap
      };
    }
    if (gap >= 0) {
      return {
        key: 'good',
        title: 'Vas bien',
        color: '#14804f',
        message: gap === 0
          ? 'Estás exactamente en el ritmo ideal acumulado para esta fecha.'
          : 'Estás por encima del ritmo ideal acumulado y tu meta diaria normal sigue siendo suficiente.',
        gap
      };
    }
    if (needed <= normal) {
      return {
        key: 'recoverable',
        title: 'Un poco bajo, aún recuperable',
        color: '#9b6500',
        message: 'Estás bajo el ritmo ideal, pero mantener la meta diaria normal todavía permite cerrar el mes.',
        gap
      };
    }
    return {
      key: 'effort',
      title: 'Necesitas un esfuerzo adicional',
      color: '#b42318',
      message: `La meta diaria normal ya no alcanza. Desde ahora necesitas aproximadamente ${needed} agendas por día activo.`,
      gap
    };
  }

  global.StatsFinancialRules = Object.freeze({
    plannedRows,
    targetForWeek,
    streakForMonth,
    rhythmState
  });
})(typeof window === 'undefined' ? globalThis : window);
