'use strict';
(function statsFinancialPreview(){
  const REFRESH_MS=30000;
  const runtime=window.AppDev;
  const rules=window.StatsFinancialRules;
  const $=id=>document.getElementById(id);
  const clamp=(value,min,max)=>Math.min(max,Math.max(min,value));
  const number=value=>Number.isFinite(Number(value))?Number(value):0;
  const escapeHtml=value=>String(value??'').replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[char]));
  const formatMoney=value=>new Intl.NumberFormat('es-CL',{style:'currency',currency:'CLP',maximumFractionDigits:0}).format(number(value));
  const formatNumber=(value,digits=0)=>new Intl.NumberFormat('es-CL',{minimumFractionDigits:digits,maximumFractionDigits:digits}).format(number(value));
  const formatTime=value=>new Intl.DateTimeFormat('es-CL',{timeZone:'America/Santiago',hour:'2-digit',minute:'2-digit',second:'2-digit'}).format(value);
  let client=null;
  let currentData=null;
  let selectedPeriod='today';
  let chartUnit='agendas';
  let timer=null;
  let loading=false;

  function assertRuntime(){
    if(!runtime||!runtime.supabase||!runtime.auth)throw new Error('Runtime modular DEV no disponible');
    if(!rules)throw new Error('Reglas de Stats DEV no disponibles');
    if(runtime.environment?.supabaseProjectRef!=='xcujixexjbuqqzlbomgw')throw new Error('Bloqueo de seguridad: proyecto distinto de DEV');
    client=runtime.supabase.getClient();
  }

  function showOnly(view){
    ['loading','error-view','dashboard'].forEach(id=>$(id).classList.toggle('hidden',id!==view));
  }

  function showLogin(show){$('login-layer').classList.toggle('hidden',!show)}

  function validatePayload(data){
    if(!data||data.ok!==true)throw new Error('Respuesta inválida de get_stats_cockpit_v1');
    if(data.metric_contract!=='daily_person_outcome_v1')throw new Error('Contrato métrico inesperado');
    if(data.value_contract!=='agenda_expected_value_v1')throw new Error('Contrato de valor inesperado');
    if(!data.goal||!data.periods||!data.month||!data.month_story)throw new Error('Respuesta incompleta de la RPC');
    return data;
  }

  function progress(actual,target){return target>0?actual/target:0}

  function periodModels(data){
    const perAgendaClp=number(data.goal.estimated_clp_per_agenda);
    const cnsPerAgenda=number(data.goal.estimated_cns_per_agenda);
    const weekTarget=rules.targetForWeek(data);
    const definitions=[
      {key:'today',name:'Día',className:'day',actual:number(data.periods.today?.agendas),target:number(data.goal.today_target_agendas),icon:'sun'},
      {key:'week',name:'Semana',className:'week',actual:number(data.periods.week?.agendas),target:weekTarget,icon:'calendar'},
      {key:'month',name:'Mes calendario',className:'month',actual:number(data.month.actual_agendas),target:number(data.goal.monthly_agendas),icon:'month'}
    ];
    return definitions.map(item=>({...item,
      actualClp:item.actual*perAgendaClp,targetClp:item.target*perAgendaClp,
      actualCns:item.actual*cnsPerAgenda,targetCns:item.target*cnsPerAgenda,
      pct:progress(item.actual,item.target)
    }));
  }

  function iconSvg(kind){
    const common='width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"';
    if(kind==='sun')return `<svg ${common}><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.42 1.42M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.42-1.42M17.66 6.34l1.41-1.41"/></svg>`;
    return `<svg ${common}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M8 3v4M16 3v4M3 10h18"/></svg>`;
  }

  function renderPeriods(data){
    const cards=periodModels(data);
    $('period-grid').innerHTML=cards.map(card=>{
      const targetText=card.target>0?`${Math.round(card.pct*100)}% de ${formatNumber(card.target)} agendas`:'Sin meta para este período';
      return `<button class="period-card ${card.className} ${card.key===selectedPeriod?'active':''}" data-period="${card.key}">
        <div class="period-top"><span class="period-name">${escapeHtml(card.name)}</span><span class="period-icon">${iconSvg(card.icon)}</span></div>
        <div class="period-money">${formatMoney(card.actualClp)}</div><div class="period-money-label">esperados</div>
        <div class="period-facts"><strong>${formatNumber(card.actual)}</strong> agendas · ${formatNumber(card.actualCns,1)} CNS</div>
        <div class="period-bar"><span style="width:${clamp(card.pct*100,0,100)}%"></span></div>
        <div class="period-progress">${escapeHtml(targetText)}</div>
      </button>`;
    }).join('');
    document.querySelectorAll('[data-period]').forEach(button=>button.addEventListener('click',()=>{
      selectedPeriod=button.dataset.period;
      renderPeriods(currentData);renderOperations(currentData);
    }));
  }

  function renderHero(data){
    const actualAgendas=number(data.periods.today?.agendas);
    const targetAgendas=number(data.goal.today_target_agendas);
    const perAgendaClp=number(data.goal.estimated_clp_per_agenda);
    const cnsPerAgenda=number(data.goal.estimated_cns_per_agenda);
    const actualClp=actualAgendas*perAgendaClp;
    const targetClp=targetAgendas*perAgendaClp;
    const gapAgendas=Math.max(0,targetAgendas-actualAgendas);
    const pct=progress(actualAgendas,targetAgendas);
    $('hero-money').textContent=formatMoney(actualClp);
    $('hero-agendas').textContent=`${formatNumber(actualAgendas)} agendas`;
    $('hero-cns').textContent=`${formatNumber(actualAgendas*cnsPerAgenda,1)} CNS esperados`;
    $('hero-progress').style.width=`${targetAgendas>0?clamp(pct*100,0,100):0}%`;
    if(targetAgendas<=0){
      $('hero-target').innerHTML='La meta de hoy es <strong>0</strong>.';
      $('hero-message').textContent=actualAgendas>0?'Tus agendas igualmente suman valor esperado al mes.':'Configura una Meta Mensual para comparar el avance diario.';
      return;
    }
    $('hero-target').innerHTML=`${formatMoney(actualClp)} de <strong>${formatMoney(targetClp)}</strong> esperados para hoy`;
    if(actualAgendas===0){
      $('hero-message').textContent=`Todavía no sumas dinero esperado hoy. Tu primera agenda agrega ${formatMoney(perAgendaClp)} y ${formatNumber(cnsPerAgenda,1)} CNS esperados.`;
    }else if(actualAgendas<targetAgendas){
      $('hero-message').textContent=`Llevas ${Math.round(pct*100)}% de la meta de hoy. Te faltan ${formatMoney(gapAgendas*perAgendaClp)}, ${formatNumber(gapAgendas*cnsPerAgenda,1)} CNS y ${formatNumber(gapAgendas)} agendas.`;
    }else if(actualAgendas===targetAgendas){
      $('hero-message').textContent='Alcanzaste exactamente la meta de hoy. Cada agenda adicional aumenta tu ventaja mensual.';
    }else{
      const excess=actualAgendas-targetAgendas;
      $('hero-message').textContent=`Superaste la meta de hoy por ${formatMoney(excess*perAgendaClp)}, ${formatNumber(excess*cnsPerAgenda,1)} CNS y ${formatNumber(excess)} agendas.`;
    }
  }

  function renderRhythm(data){
    const state=rules.rhythmState(data);
    const actual=number(data.month.actual_agendas);
    const monthly=number(data.goal.monthly_agendas);
    const expected=number(data.month.expected_through_today);
    const normal=number(data.goal.normal_daily_agendas);
    const needed=number(data.month.needed_daily_to_finish);
    const perAgendaClp=number(data.goal.estimated_clp_per_agenda);
    const cnsPerAgenda=number(data.goal.estimated_cns_per_agenda);
    const completion=monthly>0?actual/monthly:0;
    const ringPct=monthly>0?clamp(completion*100,0,100):0;
    $('rhythm-title').textContent=state.title;
    $('rhythm-card').style.setProperty('--state-color',state.color);
    $('rhythm-ring').style.setProperty('--ring-pct',ringPct);
    $('rhythm-percent').textContent=`${Math.round(ringPct)}%`;
    $('rhythm-copy').innerHTML=`<strong>${escapeHtml(state.message)}</strong>${monthly>0?`Llevas ${formatNumber(actual)} de ${formatNumber(monthly)} agendas y ${formatMoney(actual*perAgendaClp)} esperados.`:'La meta configurada es 0.'}`;
    const streak=rules.streakForMonth(data);
    $('streak-chip').className=`streak ${streak.enabled&&streak.count>0?'on':''}`;
    $('streak-chip').textContent=!streak.enabled?'Racha desactivada':streak.count>0?`Racha del mes: ${streak.count} día${streak.count===1?'':'s'}`:'Sin racha activa';
    let gapLabel='Brecha al ritmo';
    let signedAgendas=number(data.month.gap_to_pace);
    if(state.key==='complete'){gapLabel='Sobre la meta';signedAgendas=Math.max(0,actual-monthly)}
    if(state.key==='none')signedAgendas=0;
    const absolute=Math.abs(signedAgendas);
    const sign=signedAgendas>0?'+':signedAgendas<0?'−':'';
    $('gap-box').innerHTML=`
      <div class="gap-item"><div class="gap-label">${gapLabel}</div><div class="gap-value">${sign}${formatNumber(absolute)} agendas</div></div>
      <div class="gap-item"><div class="gap-label">CNS esperados</div><div class="gap-value">${sign}${formatNumber(absolute*cnsPerAgenda,1)}</div></div>
      <div class="gap-item"><div class="gap-label">Dinero esperado</div><div class="gap-value">${sign}${formatMoney(absolute*perAgendaClp)}</div></div>`;
    $('rhythm-bar').style.width=`${monthly>0?clamp(actual/monthly*100,0,100):0}%`;
    $('rhythm-current').textContent=monthly>0?`Avance real: ${formatNumber(actual)} agendas`:'Avance real sin meta';
    $('rhythm-ideal').textContent=monthly>0?`Ritmo ideal a hoy: ${formatNumber(expected)} · normal ${formatNumber(normal)}/día · necesario ${formatNumber(needed)}/día`:'Ritmo ideal no disponible';
  }

  function chartSeries(data){
    const rows=rules.plannedRows(data);
    const today=String(data.month_story.today||'');
    const actualToday=number(data.month.actual_agendas);
    const projectedEnd=Math.max(actualToday,number(data.month.projected_end_at_current_pace));
    const futureActive=rows.filter(row=>row.day>today&&row.is_workday).length;
    let futureIndex=0;
    return rows.map(row=>{
      let forecast=null;
      if(row.day===today)forecast=actualToday;
      else if(row.day>today){
        if(row.is_workday)futureIndex++;
        const ratio=futureActive>0?futureIndex/futureActive:1;
        forecast=actualToday+(projectedEnd-actualToday)*ratio;
      }
      return {day:row.day,actual:row.actual_cumulative==null?null:number(row.actual_cumulative),ideal:number(row.expected_cumulative),forecast};
    });
  }

  function chartValue(value,data){return chartUnit==='money'?value*number(data.goal.estimated_clp_per_agenda):value}
  function axisLabel(value){
    if(chartUnit==='money'){
      if(value>=1000000)return `$${formatNumber(value/1000000,1)}M`;
      if(value>=1000)return `$${formatNumber(value/1000,0)}k`;
      return formatMoney(value);
    }
    return formatNumber(value);
  }
  function pathFor(points,xScale,yScale){
    const valid=points.filter(point=>point.value!=null);
    return valid.map((point,index)=>`${index?'L':'M'} ${xScale(point.index).toFixed(2)} ${yScale(point.value).toFixed(2)}`).join(' ');
  }

  function renderChart(data){
    const series=chartSeries(data);
    const width=680,height=210,pad={l:58,r:14,t:15,b:30};
    const actual=series.map((row,index)=>({index,value:row.actual==null?null:chartValue(row.actual,data)}));
    const ideal=series.map((row,index)=>({index,value:chartValue(row.ideal,data)}));
    const forecast=series.map((row,index)=>({index,value:row.forecast==null?null:chartValue(row.forecast,data)}));
    const all=[...actual,...ideal,...forecast].map(item=>item.value).filter(value=>value!=null);
    const max=Math.max(1,...all)*1.08;
    const x=index=>pad.l+(index/Math.max(1,series.length-1))*(width-pad.l-pad.r);
    const y=value=>pad.t+(1-value/max)*(height-pad.t-pad.b);
    const ticks=[0,.5,1].map(ratio=>({ratio,value:max*ratio}));
    const todayIndex=Math.max(0,series.findIndex(row=>row.day===String(data.month_story.today||'')));
    const actualPath=pathFor(actual,x,y),idealPath=pathFor(ideal,x,y),forecastPath=pathFor(forecast,x,y);
    $('chart-wrap').innerHTML=`<svg viewBox="0 0 ${width} ${height}" role="img" aria-label="Avance mensual en ${chartUnit==='money'?'dinero esperado':'agendas'}">
      ${ticks.map(tick=>`<line x1="${pad.l}" y1="${y(tick.value)}" x2="${width-pad.r}" y2="${y(tick.value)}" stroke="#dfe6ef" stroke-width="1"/><text x="${pad.l-8}" y="${y(tick.value)+4}" text-anchor="end" fill="#778397" font-size="11">${escapeHtml(axisLabel(tick.value))}</text>`).join('')}
      <line x1="${x(todayIndex)}" y1="${pad.t}" x2="${x(todayIndex)}" y2="${height-pad.b}" stroke="#bcc6d5" stroke-width="1" stroke-dasharray="3 4"/>
      <path d="${idealPath}" fill="none" stroke="#aeb8c8" stroke-width="2"/>
      <path d="${actualPath}" fill="none" stroke="#315ed8" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="${forecastPath}" fill="none" stroke="#6846cc" stroke-width="3" stroke-dasharray="8 7" stroke-linecap="round"/>
      <circle cx="${x(todayIndex)}" cy="${y(chartValue(number(data.month.actual_agendas),data))}" r="5" fill="#315ed8" stroke="white" stroke-width="3"/>
      <text x="${pad.l}" y="${height-8}" fill="#778397" font-size="11">1</text>
      <text x="${x(todayIndex)}" y="${height-8}" text-anchor="middle" fill="#536078" font-size="11">Hoy</text>
      <text x="${width-pad.r}" y="${height-8}" text-anchor="end" fill="#778397" font-size="11">Fin de mes</text>
    </svg>`;
    const projected=number(data.month.projected_end_at_current_pace);
    $('chart-sub').textContent=chartUnit==='money'?`Proyección al cierre: ${formatMoney(projected*number(data.goal.estimated_clp_per_agenda))} esperados.`:`Proyección al cierre: ${formatNumber(projected)} agendas.`;
  }

  function renderOperations(data){
    const period=data.periods[selectedPeriod]||data.periods.today||{};
    const periodNames={today:'Hoy',week:'Semana calendario',month:'Mes calendario'};
    $('ops-period').textContent=periodNames[selectedPeriod];
    const worked=number(period.worked_contacts);
    const effective=number(period.effective_calls);
    const agendas=number(period.agendas);
    const conversion=period.effective_conversion_rate==null?null:number(period.effective_conversion_rate);
    const perAgenda=period.worked_per_agenda==null?null:number(period.worked_per_agenda);
    $('ops-grid').innerHTML=`
      <div class="op"><div class="op-label">Contactos trabajados</div><div class="op-value">${formatNumber(worked)}</div><div class="op-note">${formatNumber(effective)} llamadas efectivas.</div></div>
      <div class="op"><div class="op-label">Conversión efectiva</div><div class="op-value">${conversion==null?'—':formatNumber(conversion,1)+'%'}</div><div class="op-note">Agendas sobre llamadas efectivas.</div></div>
      <div class="op"><div class="op-label">Trabajados / agenda</div><div class="op-value">${perAgenda==null?'—':formatNumber(perAgenda,1)}</div><div class="op-note">${formatNumber(agendas)} agendas en el período.</div></div>`;
  }

  function renderMeta(data){
    $('equivalence-line').textContent=`1 agenda = ${formatNumber(data.goal.estimated_cns_per_agenda,1)} CNS = ${formatMoney(data.goal.estimated_clp_per_agenda)} esperados`;
    $('contract-line').textContent=`${data.metric_contract} · ${data.value_contract}`;
    $('updated-label').textContent=`Actualizado ${formatTime(new Date(data.generated_at||Date.now()))}`;
  }

  function render(data){
    currentData=data;
    renderHero(data);renderPeriods(data);renderRhythm(data);renderChart(data);renderOperations(data);renderMeta(data);
    showOnly('dashboard');
  }

  async function load(){
    if(loading)return;
    loading=true;$('refresh-btn').disabled=true;
    if(!currentData)showOnly('loading');
    try{
      const {data,error}=await client.rpc('get_stats_cockpit_v1');
      if(error)throw error;
      render(validatePayload(data));
    }catch(error){
      console.error('Stats preview RPC error',error);
      $('error-text').textContent=`Error en get_stats_cockpit_v1: ${error?.message||String(error)}`;
      showOnly('error-view');
    }finally{loading=false;$('refresh-btn').disabled=false}
  }

  function startRefresh(){
    clearInterval(timer);timer=setInterval(()=>{if(document.visibilityState==='visible')load()},REFRESH_MS);
  }

  async function init(){
    try{
      assertRuntime();
      const session=await runtime.auth.getSession();
      showLogin(!session);
      if(session){await load();startRefresh()}
      runtime.auth.onChange(async(_event,nextSession)=>{
        showLogin(!nextSession);
        if(nextSession){await load();startRefresh()}else{clearInterval(timer);currentData=null;showOnly('loading')}
      });
    }catch(error){
      $('error-text').textContent=error?.message||String(error);showOnly('error-view');
    }
  }

  $('login-form').addEventListener('submit',async event=>{
    event.preventDefault();$('login-error').textContent='';
    try{await runtime.auth.signIn($('login-email').value.trim(),$('login-pass').value)}
    catch(error){$('login-error').textContent=error?.message||String(error)}
  });
  $('login-magic').addEventListener('click',async()=>{
    $('login-error').textContent='';
    const email=$('login-email').value.trim();
    if(!email){$('login-error').textContent='Ingresa tu correo.';return}
    try{await runtime.auth.signInWithOtp(email);$('login-error').textContent='Enlace enviado. Revisa tu correo.'}
    catch(error){$('login-error').textContent=error?.message||String(error)}
  });
  $('refresh-btn').addEventListener('click',load);$('retry-btn').addEventListener('click',load);
  document.querySelectorAll('[data-unit]').forEach(button=>button.addEventListener('click',()=>{
    chartUnit=button.dataset.unit;document.querySelectorAll('[data-unit]').forEach(item=>item.classList.toggle('active',item===button));if(currentData)renderChart(currentData);
  }));
  document.addEventListener('visibilitychange',()=>{if(document.visibilityState==='visible'&&currentData)load()});
  window.addEventListener('focus',()=>{if(currentData)load()});
  init();
})();
