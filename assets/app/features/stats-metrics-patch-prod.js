(function installProdStatsMetricsPatch(global){
  'use strict';

  const PATCH_ID='LCD-20260713-01';
  let installed=false;

  const byId=id=>document.getElementById(id);
  const num=value=>Number(value||0);
  const format=value=>num(value).toLocaleString('es-CL');
  const percent=value=>value==null?'–':Number(value).toLocaleString('es-CL',{maximumFractionDigits:1})+'%';
  const breakdownValue=(breakdown,label)=>Number((breakdown||{})[label]||0);
  const getClient=()=>typeof sb!=='undefined'?sb:null;

  function agendaLine(row){
    const name=String(row?.nombre||'Sin nombre');
    const rut=String(row?.rut||row?.rut_norm||'').trim();
    return '- '+name+(rut?' · '+rut:'');
  }

  function correctedStory(story,dailySeries){
    const source=story||{};
    const daily={};
    (Array.isArray(dailySeries)?dailySeries:[]).forEach(row=>{daily[row.day]=num(row.daily_agendas);});
    let derivedCumulative=0;
    const rows=(Array.isArray(source.series)?source.series:[]).map(row=>{
      const day=String(row.day||'');
      const dayAgendas=num(daily[day]);
      derivedCumulative+=dayAgendas;
      const manualCumulative=num(row.manual_cumulative);
      const actualCumulative=manualCumulative+derivedCumulative;
      return Object.assign({},row,{
        daily_agendas:dayAgendas,
        actual_cumulative:actualCumulative,
        gap:actualCumulative-num(row.expected_cumulative)
      });
    });
    return Object.assign({},source,{series:rows});
  }

  async function patchedLoadDailyReport(){
    const blockAgendas=byId('crm-report-block1');
    const blockReport=byId('crm-report-block2');
    const client=getClient();
    if(!blockAgendas||!blockReport||!client)return;

    try{
      const {data,error}=await client.rpc('get_daily_management_report_v1',{p_date:null});
      if(error)throw error;
      const agendas=Array.isArray(data?.agenda_rows)?data.agenda_rows:[];
      const breakdown=data?.final_state_breakdown||{};
      blockAgendas.textContent='Agendamientos\n'+(agendas.length?agendas.map(agendaLine).join('\n'):'- Sin agendamientos');
      blockReport.textContent=[
        'Reporte',
        'Contactos trabajados: '+format(data?.worked_contacts),
        'Llamadas efectivas: '+format(data?.effective_calls),
        'Agendan: '+format(data?.agendas),
        'No agenda: '+format(data?.no_agenda),
        'No contactado: '+format(breakdownValue(breakdown,'No contactado')),
        'Volver a llamar: '+format(breakdownValue(breakdown,'Volver a llamar')),
        'Contacto inválido: '+format(breakdownValue(breakdown,'Contacto Inválido')),
        'Pendiente: '+format(breakdownValue(breakdown,'Pendiente'))
      ].join('\n');
    }catch(error){
      blockAgendas.textContent='Agendamientos\n- Error al cargar datos';
      blockReport.textContent='Reporte\nContactos trabajados: 0\nLlamadas efectivas: 0\nAgendan: 0\nNo agenda: 0';
      console.error('PROD stats report patch',error);
    }
  }

  async function patchedRefreshGoal(){
    let done=0,goal=0;
    const client=getClient();
    if(client){
      try{
        const {data,error}=await client.rpc('get_daily_management_report_v1',{p_date:null});
        if(error)throw error;
        done=num(data?.agendas);
        goal=await dailyGoal(currentGoalMonth());
      }catch(error){
        console.error('PROD stats goal patch',error);
      }
    }
    const text=`${done}/${goal||0}`;
    const top=byId('goal-mini-top'),topText=byId('goal-chip-text');
    if(top)top.innerHTML=ring(done,goal||1,22);
    if(topText)topText.textContent=text;
    const detail=byId('goal-mini-detail'),detailText=byId('goal-chip-detail');
    if(detail)detail.innerHTML=ring(done,goal||1,20);
    if(detailText)detailText.textContent=text;
  }

  async function patchedRenderStats(){
    const scroll=byId('stats-scroll');
    const client=getClient();
    if(!scroll)return;
    if(!client){scroll.innerHTML='<div class="empty">Configura Supabase para ver estadísticas</div>';return;}
    scroll.innerHTML='<div class="empty">Cargando estadísticas…</div>';

    try{
      const days=stats==='hoy'?1:(stats==='semana'?7:30);
      const [legacyRes,metricsRes]=await Promise.all([
        client.rpc('get_stats_v1',{p_days:days,p_goal_agendas:null}),
        client.rpc('get_management_metrics_v1',{p_days:days})
      ]);
      if(legacyRes.error)throw legacyRes.error;
      if(metricsRes.error)throw metricsRes.error;

      const legacy=legacyRes.data||{};
      const metrics=metricsRes.data||{};
      const t=metrics.today||{};
      const p=metrics.period||{};
      const derivedMonth=metrics.month||{};
      const m=legacy.month||{};
      const rawStory=legacy.month_story||{};
      const story=correctedStory(rawStory,derivedMonth.daily_series);
      const gs=await goalSettings(currentGoalMonth());

      const manualAgendas=num(m.manual_agendas??rawStory.manual_agendas);
      const actual=manualAgendas+num(derivedMonth.agendas);
      const todayAgendas=num(t.agendas);
      const todayWorked=num(t.worked_contacts);
      const todayEffective=num(t.effective_calls);
      const todayNoAgenda=num(t.no_agenda);
      const target=num(gs.monthly_goal||m.target_agendas_total);
      const totalWorkdays=workdaysInMonthCode(currentGoalMonth());
      const defaultDaily=num(gs.monthly_goal?Math.ceil(target/totalWorkdays):(m.default_daily_target||legacy.today?.goal_agendas));
      const daysLeft=num(m.business_days_left_including_today);
      const elapsedDays=num(m.business_days_through_today)||Math.max(1,totalWorkdays-daysLeft+1);
      const remainingAgendas=Math.max(0,target-actual);
      const needed=daysLeft?Math.ceil(remainingAgendas/daysLeft):0;
      const recommended=Math.max(needed,defaultDaily,num(legacy.today?.goal_agendas));
      const progress=target?Math.min(100,Math.round(actual/target*100)):0;
      const missionPct=recommended?Math.min(100,Math.round(todayAgendas/recommended*100)):0;
      const projectedCurrent=elapsedDays?Math.max(actual,Math.round(actual/elapsedDays*totalWorkdays)):actual;
      const projectedNormal=Math.max(actual,actual+defaultDaily*Math.max(0,daysLeft));
      const effectiveRate=p.effective_conversion_rate;
      const workedPerAgenda=p.worked_per_agenda;
      const paceSentence=remainingAgendas<=0
        ?'Meta mensual cumplida. Ahora la misión es sostener calidad y registrar bien.'
        :(needed>defaultDaily
          ?'La meta normal diaria ya no alcanza: necesitas una recuperación repartida en los días hábiles que quedan.'
          :'Si sostienes la meta normal diaria, todavía estás dentro del camino de cierre.');

      const sub=byId('stats-sub');
      if(sub)sub.textContent='Cockpit de trabajo, ritmo mensual y misiones';

      let html=`<div class="metric-grid"><div class="metric full"><div class="metric-label">Misión útil de hoy</div><div class="metric-number">${format(todayAgendas)} / ${format(recommended)}</div><div class="progress"><div class="fill" style="width:${missionPct}%"></div></div><div class="metric-note">Meta normal: ${format(defaultDaily)}. Para cerrar el mes conviene apuntar a ${format(needed)} agenda(s) por día útil restante.</div><div class="native-mini">${miniBlocks(recommended)}</div></div><div class="metric"><div class="metric-label">Trabajados hoy</div><div class="metric-number">${format(todayWorked)}</div><div class="metric-note">Contactos con cambio real de estado.</div></div><div class="metric"><div class="metric-label">Llamadas efectivas</div><div class="metric-number">${format(todayEffective)}</div><div class="metric-note">${format(todayAgendas)} agendan · ${format(todayNoAgenda)} no agendan.</div></div><div class="metric"><div class="metric-label">Agendamientos hoy</div><div class="metric-number">${format(todayAgendas)}</div><div class="metric-note">Resultado final Agenda.</div></div><div class="metric"><div class="metric-label">Conversión efectiva</div><div class="metric-number">${percent(effectiveRate)}</div><div class="metric-note">Agendamientos / llamadas efectivas.</div></div><div class="metric"><div class="metric-label">Trabajados / agenda</div><div class="metric-number">${workedPerAgenda==null?'–':workedPerAgenda}</div><div class="metric-note">Carga operativa por agendamiento.</div></div></div>`;
      html+=`<div class="status-list native-story"><div class="status-list-title">Historia del mes</div><div class="metric-note" style="padding:14px 18px 0">${paceSentence}</div>${chartMonth(story)}</div>`;
      html+=`<div class="native-scenarios"><div class="native-scenario"><div><b>Si sigues igual</b><div class="metric-note">Proyección al cierre.</div></div><strong>${format(projectedCurrent)}/${format(target)}</strong></div><div class="native-scenario"><div><b>Si haces lo normal</b><div class="metric-note">${format(defaultDaily)} por día útil.</div></div><strong>${format(projectedNormal)}/${format(target)}</strong></div><div class="native-scenario"><div><b>Para llegar</b><div class="metric-note">Días útiles restantes: ${format(daysLeft)}</div></div><strong>${format(needed)}/día</strong></div></div>`;
      html+=`<div class="metric-grid"><div class="metric full"><div class="metric-label">Mes laboral</div><div class="metric-number">${format(actual)} / ${format(target)}</div><div class="progress"><div class="fill" style="width:${progress}%"></div></div><div class="metric-note">Faltan ${format(remainingAgendas)} agendas. Meta diaria sugerida desde ahora: ${format(needed)}.</div></div></div>`;
      html+=reportCardSkeleton();
      scroll.innerHTML=html;
      await patchedLoadDailyReport();
    }catch(error){
      scroll.innerHTML='<div class="empty">Error al cargar estadísticas<br>'+String(error?.message||error)+'</div>';
      console.error('PROD stats render patch',error);
    }
  }

  function install(){
    if(installed)return;
    if(typeof global.renderStats!=='function'||typeof global.refreshGoal!=='function'||typeof global.reportCardSkeleton!=='function'){
      setTimeout(install,50);
      return;
    }
    global.renderStats=patchedRenderStats;
    global.loadDailyReport=patchedLoadDailyReport;
    global.refreshGoal=patchedRefreshGoal;
    global.CRM_STATS_METRICS_PATCH=PATCH_ID;
    installed=true;
    setTimeout(()=>{
      patchedRefreshGoal();
      if(typeof currentScreen!=='undefined'&&currentScreen==='stats')patchedRenderStats();
    },0);
  }

  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',install,{once:true});
  else install();
})(window);
