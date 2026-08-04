(function installProdStatsMetricsPatch(global){
  'use strict';

  const PATCH_ID='LCD-20260804-01';
  const NAVIGATION_PATCH_ID='UI-20260803-02';
  let installed=false;
  let navigationInstalled=false;
  let screenBeforeStats='contacts';

  const byId=id=>document.getElementById(id);
  const num=value=>Number(value||0);
  const format=value=>num(value).toLocaleString('es-CL');
  const decimal=value=>num(value).toLocaleString('es-CL',{maximumFractionDigits:2});
  const currency=value=>num(value).toLocaleString('es-CL',{style:'currency',currency:'CLP',maximumFractionDigits:0});
  const percent=value=>value==null?'–':Number(value).toLocaleString('es-CL',{maximumFractionDigits:1})+'%';
  const breakdownValue=(breakdown,label)=>Number((breakdown||{})[label]||0);
  const getClient=()=>typeof sb!=='undefined'?sb:null;

  function ensureStatsBackButton(){
    const topbar=byId('main-topbar');
    const title=byId('main-title');
    if(!topbar||!title)return null;

    let button=byId('stats-back-btn');
    if(!button){
      button=document.createElement('button');
      button.id='stats-back-btn';
      button.type='button';
      button.className='icon-btn';
      button.setAttribute('aria-label','Volver');
      button.setAttribute('title','Volver');
      button.style.display='none';
      button.innerHTML='<svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24" aria-hidden="true"><path d="M15 18 9 12l6-6"/></svg>';
      topbar.insertBefore(button,title);
    }

    button.onclick=()=>{
      const target=screenBeforeStats&&screenBeforeStats!=='stats'?screenBeforeStats:'contacts';
      global.setScreen(target);
    };
    return button;
  }

  function syncStatsBackButton(screen){
    const button=ensureStatsBackButton();
    if(button)button.style.display=screen==='stats'?'grid':'none';
  }

  function installStatsNavigation(){
    if(navigationInstalled)return;
    if(typeof global.setScreen!=='function'){
      setTimeout(installStatsNavigation,50);
      return;
    }
    if(global.CRM_STATS_NAVIGATION_PATCH===NAVIGATION_PATCH_ID){
      navigationInstalled=true;
      return;
    }

    const originalSetScreen=global.setScreen;
    global.setScreen=function patchedSetScreen(screen,button){
      if(screen==='stats'&&typeof currentScreen!=='undefined'&&currentScreen!=='stats'){
        screenBeforeStats=currentScreen||'contacts';
      }
      const result=originalSetScreen.call(this,screen,button);
      syncStatsBackButton(screen);
      return result;
    };

    ensureStatsBackButton();
    syncStatsBackButton(typeof currentScreen!=='undefined'?currentScreen:'contacts');
    global.CRM_STATS_NAVIGATION_PATCH=NAVIGATION_PATCH_ID;
    navigationInstalled=true;
  }

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
      blockAgendas.textContent='Agendamientos\n- Datos no disponibles';
      blockReport.textContent='Reporte\nDatos no disponibles por error de carga.';
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
      const {data,error}=await client.rpc('get_stats_cockpit_v1');
      if(error)throw error;

      const cockpit=data||{};
      const goal=cockpit.goal||{};
      const month=cockpit.month||{};
      const story=cockpit.month_story||{};
      const periods=cockpit.periods||{};
      const periodKey=stats==='hora'?'last_hour':(stats==='semana'?'week':(stats==='mes'?'month':'today'));
      const selected=periods[periodKey]||periods.today||{};
      const today=periods.today||{};
      const nextAgenda=cockpit.next_agenda||{};

      const target=num(goal.monthly_agendas);
      const normalDaily=num(goal.normal_daily_agendas);
      const todayTarget=num(goal.today_target_agendas);
      const actual=num(month.actual_agendas);
      const todayAgendas=num(today.agendas);
      const remaining=num(month.remaining_agendas);
      const expectedToday=num(month.expected_through_today);
      const gap=num(month.gap_to_pace);
      const daysLeft=num(month.active_days_left_including_today);
      const needed=num(month.needed_daily_to_finish);
      const recommended=num(month.recommended_today_agendas);
      const projectedCurrent=num(month.projected_end_at_current_pace);
      const projectedNormal=num(month.projected_end_if_normal_from_now);
      const cnsPerAgenda=num(goal.estimated_cns_per_agenda);
      const clpPerAgenda=num(goal.estimated_clp_per_agenda);
      const targetCns=num(goal.target_expected_cns);
      const targetClp=num(goal.target_expected_clp);
      const progress=target?Math.min(100,Math.round(actual/target*100)):0;
      const missionPct=recommended?Math.min(100,Math.round(todayAgendas/recommended*100)):0;
      const generated=cockpit.generated_at?new Date(cockpit.generated_at):new Date();
      const updated=generated.toLocaleTimeString('es-CL',{hour:'2-digit',minute:'2-digit'});

      const missionValue=recommended?format(todayAgendas)+' / '+format(recommended):format(todayAgendas)+' hoy';
      const missionNote=target<=0
        ?'Define la Meta Mensual en Ajustes para activar el ritmo.'
        :(recommended>todayTarget
          ?'Meta fijada en Ajustes: '+format(todayTarget)+' hoy. Recuperación sugerida: '+format(recommended)+' para sostener la meta mensual.'
          :'Meta fijada en Ajustes: '+format(todayTarget)+' hoy. La misión coincide con el ritmo mensual.');
      const paceSentence=remaining<=0
        ?'Meta mensual cumplida. Mantén la calidad y el registro correcto.'
        :(gap<0
          ?'Vas '+format(Math.abs(gap))+' bajo la línea ideal de '+format(expectedToday)+' agendas a esta fecha.'
          :'Vas '+format(gap)+' sobre la línea ideal de '+format(expectedToday)+' agendas a esta fecha.');

      const sub=byId('stats-sub');
      if(sub)sub.textContent=(selected.label||'Hoy')+' · actualizado '+updated;

      let html='<div class="metric-grid">';
      html+='<div class="metric full"><div class="metric-label">Misión útil de hoy</div><div class="metric-number">'+missionValue+'</div><div class="progress"><div class="fill" style="width:'+missionPct+'%"></div></div><div class="metric-note">'+missionNote+'</div><div class="native-mini">'+miniBlocks(recommended)+'</div><div class="metric-note" style="margin-top:12px"><b>Próxima agenda:</b> +'+decimal(nextAgenda.expected_cns||cnsPerAgenda)+' CNS / +'+currency(nextAgenda.expected_clp||clpPerAgenda)+' esperados.</div></div>';
      html+='<div class="metric full"><div class="metric-label">Pulso esperado · '+(selected.label||'Hoy')+'</div><div class="metric-number">'+currency(selected.expected_clp)+'</div><div class="metric-note">'+format(selected.agendas)+' agenda(s) = '+decimal(selected.expected_cns)+' CNS esperados. Estimación motivacional; no es producción reconocida ni ingreso devengado.</div></div>';
      html+='<div class="metric"><div class="metric-label">Trabajados</div><div class="metric-number">'+format(selected.worked_contacts)+'</div><div class="metric-note">Personas con cambio real de estado.</div></div>';
      html+='<div class="metric"><div class="metric-label">Llamadas efectivas</div><div class="metric-number">'+format(selected.effective_calls)+'</div><div class="metric-note">'+format(selected.agendas)+' agendan · '+format(selected.no_agenda)+' no agendan.</div></div>';
      html+='<div class="metric"><div class="metric-label">Agendamientos</div><div class="metric-number">'+format(selected.agendas)+'</div><div class="metric-note">Resultado final Agenda en la ventana.</div></div>';
      html+='<div class="metric"><div class="metric-label">Conversión efectiva</div><div class="metric-number">'+percent(selected.effective_conversion_rate)+'</div><div class="metric-note">Agendamientos / llamadas efectivas.</div></div></div>';

      html+='<div class="status-list native-story"><div class="status-list-title">Ritmo mensual</div><div class="metric-note" style="padding:14px 18px 0">'+paceSentence+'</div>'+chartMonth(story,projectedCurrent)+'</div>';
      html+='<div class="native-scenarios">';
      html+='<div class="native-scenario"><div><b>Si sigues igual</b><div class="metric-note">'+currency(projectedCurrent*clpPerAgenda)+' esperados.</div></div><strong>'+format(projectedCurrent)+'/'+format(target)+'</strong></div>';
      html+='<div class="native-scenario"><div><b>Si haces lo normal</b><div class="metric-note">'+format(normalDaily)+' por día útil · '+currency(projectedNormal*clpPerAgenda)+' esperados.</div></div><strong>'+format(projectedNormal)+'/'+format(target)+'</strong></div>';
      html+='<div class="native-scenario"><div><b>Para llegar</b><div class="metric-note">'+format(daysLeft)+' días útiles · '+decimal(needed*cnsPerAgenda)+' CNS/día.</div></div><strong>'+format(needed)+'/día</strong></div></div>';

      html+='<div class="metric-grid"><div class="metric full"><div class="metric-label">Meta del mes desde Ajustes</div><div class="metric-number">'+format(actual)+' / '+format(target)+'</div><div class="progress"><div class="fill" style="width:'+progress+'%"></div></div><div class="metric-note">'+decimal(month.actual_expected_cns)+' / '+decimal(targetCns)+' CNS esperados · '+currency(month.actual_expected_clp)+' / '+currency(targetClp)+'. Faltan '+format(remaining)+' agendas.</div></div></div>';
      html+=reportCardSkeleton();
      scroll.innerHTML=html;
      await patchedLoadDailyReport();
    }catch(error){
      scroll.innerHTML='<div class="empty">Datos estadísticos no disponibles<br>'+String(error?.message||error)+'</div>';
      console.error('PROD stats render patch',error);
    }
  }

  function install(){
    if(installed)return;
    installStatsNavigation();
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
