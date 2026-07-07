const APP_VERSION='crm-llamados-github-wrapper-v85-july-assigned';
const APP_CACHE=APP_VERSION+'-shell';
const SUPA='https://ojaimqutuycralrjbxwr.supabase.co';
const APP_SOURCE_PREFIX=SUPA+'/storage/v1/object/public/pwa/index.html';
const ACTIVE_PERIOD='2026-07';
const REAL_MONTHS=[
  {period:'2026-06',rows:89948,distinct_ruts:89948},
  {period:'2026-05',rows:95608,distinct_ruts:95607},
  {period:'2026-04',rows:65275,distinct_ruts:65275},
  {period:'2026-03',rows:67241,distinct_ruts:67241},
  {period:'2026-02',rows:72758,distinct_ruts:72758}
];
const DEFAULT_TOTAL=150;
const DEFAULT_PENDING=115;
const DEFAULT_ASSIGNED=150;
const SHELL_ASSETS=['./','./index.html','./manifest.webmanifest','./icons/icon.svg','./assets/logo-horizontal.svg','./sprint.js'];

self.addEventListener('install',event=>{self.skipWaiting();event.waitUntil(caches.open(APP_CACHE).then(cache=>cache.addAll(SHELL_ASSETS)).catch(()=>null));});
self.addEventListener('message',event=>{if(event.data&&event.data.type==='SKIP_WAITING')self.skipWaiting();});
self.addEventListener('activate',event=>{event.waitUntil((async()=>{const keys=await caches.keys();await Promise.all(keys.filter(key=>key!==APP_CACHE).map(key=>caches.delete(key)));await self.clients.claim();const wins=await self.clients.matchAll({type:'window',includeUncontrolled:true});await Promise.all(wins.map(client=>{try{const url=new URL(client.url);if(url.searchParams.get('_swv')!==APP_VERSION){url.searchParams.set('_swv',APP_VERSION);return client.navigate(url.href);}}catch(e){}return Promise.resolve();}));})());});

function copyHeaders(req){const out={};['apikey','authorization','x-client-info'].forEach(key=>{const value=req.headers.get(key);if(value)out[key]=value;});out.accept='application/json';return out;}
function okJson(obj){return new Response(JSON.stringify(obj),{status:200,headers:{'content-type':'application/json; charset=utf-8','access-control-allow-origin':'*'}});}
function enc(value){return encodeURIComponent(String(value));}
function pgArray(values){return '{'+values.map(v=>String(v).replace(/[{}]/g,'')).join(',')+'}';}
function pgList(values){return '('+values.map(v=>'"'+String(v).replace(/"/g,'')+'"').join(',')+')';}
function monthInfo(params){const real=new Set(REAL_MONTHS.map(m=>m.period));const raw=Array.isArray(params.p_months)?params.p_months.filter(Boolean):[];const months=raw.filter(m=>real.has(m));const allReal=REAL_MONTHS.every(m=>raw.includes(m.period));return{raw,months,allReal};}
function escapeLike(s){return String(s||'').trim().replace(/[*,()]/g,'');}

function patchAppHtml(html){
  const sprintStateCss='<style id="crm-sprint-state-css">#crm-sprint-chip.idle{background:#E8EEF7!important;color:#0F172A!important;border:1px solid #CBD5E1!important;box-shadow:none!important}#crm-sprint-chip.paused{background:#64748B!important;color:#fff!important;border:0!important}#crm-sprint-chip.warn{background:#BA1A1A!important;color:#fff!important;border:0!important}#crm-sprint-chip:not(.idle):not(.paused):not(.warn){background:#166534!important;color:#fff!important;border:0!important}</style>';
  const versionBlock='<div class="settings-section" id="crm-version-section"><label class="settings-label">Versión de la app</label><div class="settings-note" style="margin:8px 2px 0">v85 · crm llamados · '+APP_VERSION+'</div></div>';
  let out=html.split('Contactos test').join('Contactos');
  if(!out.includes('id="crm-sprint-state-css"')) out=out.split('</head>').join(sprintStateCss+'</head>');
  if(!out.includes('id="crm-version-section"')) out=out.split('<div class="settings-actions"><button class="sheet-close"').join(versionBlock+'<div class="settings-actions"><button class="sheet-close"');
  if(!out.includes('id="crm-sprint-chip"')) out=out.split('<button class="goal-chip"').join('<button id="crm-sprint-chip" class="idle" type="button" style="height:38px;border:1px solid #CBD5E1;border-radius:19px;background:#E8EEF7;color:#0F172A;font-weight:800;font-size:12.5px;padding:0 11px;display:flex;align-items:center;gap:6px;white-space:nowrap"><span id="crm-sprint-chip-txt">Sprint</span></button><button class="goal-chip"');
  if(!out.includes('sprint.js?v=85')) out=out.split('</body>').join('<script src="./sprint.js?v=85"></script></body>');
  return out;
}
async function patchAppSource(req){const res=await fetch(req,{cache:'no-store'});const html=await res.text();const headers=new Headers(res.headers);headers.set('content-type','text/html; charset=utf-8');headers.set('cache-control','no-store');return new Response(patchAppHtml(html),{status:res.status,statusText:res.statusText,headers});}
async function exactCount(path,headers){const res=await fetch(SUPA+path,{method:'GET',headers:{...headers,prefer:'count=exact'},mode:'cors'});const range=res.headers.get('content-range')||'';const match=range.match(/\/(\d+)$/);return match?Number(match[1]):0;}

function buildConds(params){
  const situation=params.p_situation||'gestionables';
  const search=String(params.p_search||'').trim().toLowerCase();
  const mi=monthInfo(params);
  const types=Array.isArray(params.p_types)?params.p_types.filter(Boolean):[];
  const mode=params.p_month_mode||'any';
  const cond=['active_period=eq.'+enc(ACTIVE_PERIOD)];
  if(situation==='gestionables')cond.push('gestionable_actual=eq.true');
  else if(situation==='no_gestionables'||situation==='no-gestionables')cond.push('gestionable_actual=eq.false');
  if(types.length===1&&types[0]==='asignado')cond.push('motivo_gestionabilidad=eq.asignado');
  else if(types.length===1&&types[0]==='regla')cond.push('motivo_gestionabilidad=eq.disponible_por_regla');
  else if(types.length>1)cond.push('motivo_gestionabilidad=in.(asignado,disponible_por_regla)');
  if(params.p_pending_only)cond.push('estado_gestion=eq.Pendiente');
  if(params.p_assigned_only)cond.push('motivo_gestionabilidad=eq.asignado');
  if(search)cond.push('search_text=like.*'+enc(escapeLike(search))+'*');
  if(mi.months.length&&!mi.allReal){
    if(mode==='all')cond.push('meses_aparicion=cs.'+enc(pgArray(mi.months)));
    else if(mode==='only'){cond.push('meses_aparicion=cs.'+enc(pgArray(mi.months)));cond.push('meses_aparicion=cd.'+enc(pgArray(mi.months)));}
    else cond.push('meses_aparicion=ov.'+enc(pgArray(mi.months)));
  }else if(mi.raw.length&&!mi.allReal){cond.push('rut_norm=eq.__no_real_month_selected__');}
  return cond;
}

function shouldUseWorkQueue(params){
  const situation=params.p_situation||'gestionables';
  const types=Array.isArray(params.p_types)?params.p_types.filter(Boolean):[];
  if(situation==='no_gestionables'||situation==='no-gestionables')return false;
  if(types.length===1&&types[0]==='regla')return false;
  const mi=monthInfo(params);
  if(mi.raw.length&&!mi.allReal)return false;
  return true;
}

async function fallbackWorkQueue(params,headers,limit,offset){
  if(!shouldUseWorkQueue(params))return okJson({ok:true,source:'lite_v85_work_queue_empty',active_period:ACTIVE_PERIOD,limit,offset,base_total:0,base_pending:0,base_assigned:0,base_gestionables:0,base_no_gestionables:0,result_total:0,rows:[]});
  const cond=['period=eq.'+enc(ACTIVE_PERIOD),'visible=eq.true','origen=eq.asignado'];
  if(params.p_pending_only)cond.push('estado_gestion=eq.Pendiente');
  const search=escapeLike(params.p_search||'');
  if(search)cond.push('or=(nombre.ilike.*'+enc(search)+'*,rut_norm.ilike.*'+enc(search)+'*,telefono_1.ilike.*'+enc(search)+'*,telefono_2.ilike.*'+enc(search)+'*,telefono_3.ilike.*'+enc(search)+'*)');
  const baseCond=cond.join('&');
  const select='work_item_id,contact_id,rut_norm,period,campaign_key,campaign_name,campaign_desc,estado_gestion,fecha_estado_gestion,ingreso_estimado,comentarios,recordatorio_titulo,recordatorio_fecha_hora,ultimo_contacto,nombre,telefono_1,telefono_2,telefono_3,email,display_order,source_order';
  const path='/rest/v1/work_queue?select='+select+'&'+baseCond+'&order=display_order.asc.nullslast&order=source_order.asc.nullslast&order=rut_norm.asc&limit='+limit+'&offset='+offset;
  const countPath='/rest/v1/work_queue?select=work_item_id&'+baseCond+'&limit=1';
  const pendingPath='/rest/v1/work_queue?select=work_item_id&period=eq.'+enc(ACTIVE_PERIOD)+'&visible=eq.true&origen=eq.asignado&estado_gestion=eq.Pendiente&limit=1';
  const [rows,total,pending]=await Promise.all([
    fetch(SUPA+path,{headers,mode:'cors'}).then(r=>r.ok?r.json():[]),
    exactCount(countPath,headers),
    exactCount(pendingPath,headers).catch(()=>DEFAULT_PENDING)
  ]);
  const mapped=(rows||[]).map(row=>({
    active_period:ACTIVE_PERIOD,
    contact_id:row.contact_id,
    rut_norm:row.rut_norm,
    work_item_id:row.work_item_id,
    campaign_key:row.campaign_key,
    campaign_name:row.campaign_name,
    campaign_desc:row.campaign_desc,
    estado_gestion:row.estado_gestion||'Pendiente',
    fecha_estado_gestion:row.fecha_estado_gestion,
    ingreso_estimado:row.ingreso_estimado,
    comentarios:row.comentarios,
    recordatorio_titulo:row.recordatorio_titulo,
    recordatorio_fecha_hora:row.recordatorio_fecha_hora,
    ultimo_contacto:row.ultimo_contacto,
    meses_aparicion:[],
    ultimo_mes_observado:null,
    ultimo_estado_observado:null,
    aparece_en_campana_activa:false,
    asignado_a_mi:true,
    gestionable_actual:true,
    motivo_gestionabilidad:'asignado',
    motivo_label:'Asignado',
    display_order:row.display_order,
    rut:row.rut_norm,
    nombre:row.nombre||'',
    telefono_1:row.telefono_1||'',
    telefono_2:row.telefono_2||'',
    telefono_3:row.telefono_3||'',
    telefono_activo_idx:null,
    email:row.email||''
  }));
  return okJson({ok:true,source:'lite_v85_work_queue_july',active_period:ACTIVE_PERIOD,limit,offset,base_total:Number(total||0),base_pending:Number(pending||0),base_assigned:Number(total||0),base_gestionables:Number(total||0),base_no_gestionables:0,result_total:Number(total||0),rows:mapped});
}

async function fallbackGetContactsV2(req){
  let params={};try{params=await req.clone().json();}catch(e){}
  const limit=Math.max(1,Math.min(Number(params.p_limit||50),200));
  const offset=Math.max(0,Number(params.p_offset||0));
  const headers=copyHeaders(req);
  const cond=buildConds(params);
  const baseCond=cond.join('&');
  const select='active_period,contact_id,rut_norm,work_item_id,campaign_key,campaign_name,campaign_desc,estado_gestion,fecha_estado_gestion,ingreso_estimado,comentarios,recordatorio_titulo,recordatorio_fecha_hora,ultimo_contacto,meses_aparicion,ultimo_mes_observado,ultimo_estado_observado,aparece_en_campana_activa,asignado_a_mi,gestionable_actual,motivo_gestionabilidad,display_order';
  const order='order=display_order.asc.nullslast&order=motivo_gestionabilidad.asc.nullslast&order=rut_norm.asc';
  const path='/rest/v1/contact_operational_state_v2?select='+select+'&'+baseCond+'&'+order+'&limit='+limit+'&offset='+offset;
  const mi=monthInfo(params);
  const noMonthFilter=!mi.raw.length||mi.allReal;
  const isDefault=(params.p_situation||'gestionables')==='gestionables'&&!String(params.p_search||'').trim()&&noMonthFilter&&!(Array.isArray(params.p_types)&&params.p_types.length)&&!params.p_pending_only&&!params.p_assigned_only;
  const totalPromise=isDefault?Promise.resolve(DEFAULT_TOTAL):exactCount('/rest/v1/contact_operational_state_v2?select=rut_norm&'+baseCond+'&limit=1',headers);
  const rowsPromise=fetch(SUPA+path,{headers,mode:'cors'}).then(res=>{if(!res.ok)throw new Error('contacts fallback base '+res.status);return res.json();});
  const [baseRows,total]=await Promise.all([rowsPromise,totalPromise]);
  if((!baseRows||!baseRows.length)&&Number(total||0)===0){return fallbackWorkQueue(params,headers,limit,offset);}
  const ruts=[...new Set(baseRows.map(row=>row.rut_norm).filter(Boolean))];
  const contactMap={};
  if(ruts.length){
    const contactPath='/rest/v1/contacts?select=contact_id,rut_norm,rut,nombre,telefono_1,telefono_2,telefono_3,email,telefono_activo_idx&rut_norm=in.'+encodeURIComponent(pgList(ruts));
    const contacts=await fetch(SUPA+contactPath,{headers,mode:'cors'}).then(res=>res.ok?res.json():[]);
    contacts.forEach(c=>{contactMap[c.rut_norm]=c;});
  }
  const rows=baseRows.map(row=>{const c=contactMap[row.rut_norm]||{};return {...row,contact_id:c.contact_id||row.contact_id,rut:c.rut||row.rut_norm,nombre:c.nombre||'',telefono_1:c.telefono_1||'',telefono_2:c.telefono_2||'',telefono_3:c.telefono_3||'',telefono_activo_idx:c.telefono_activo_idx??null,email:c.email||'',motivo_label:row.motivo_gestionabilidad==='asignado'?'Asignado':(row.motivo_gestionabilidad==='disponible_por_regla'?'Disponible por regla':'Histórico informativo')};});
  return okJson({ok:true,source:'lite_v85_cos',active_period:ACTIVE_PERIOD,limit,offset,base_total:Number(total||0),base_pending:isDefault?DEFAULT_PENDING:Number(total||0),base_assigned:isDefault?DEFAULT_ASSIGNED:0,base_gestionables:isDefault?DEFAULT_TOTAL:Number(total||0),base_no_gestionables:0,result_total:Number(total||0),rows});
}

self.addEventListener('fetch',event=>{
  const req=event.request;
  if(req.method==='GET'&&req.url.startsWith(APP_SOURCE_PREFIX)){event.respondWith(patchAppSource(req).catch(()=>fetch(req)));return;}
  if(req.method==='POST'&&req.url.startsWith(SUPA+'/rest/v1/rpc/get_contacts_v2_months')){event.respondWith(okJson({ok:true,source:'lite_v85_months',months:REAL_MONTHS}));return;}
  if(req.method==='POST'&&req.url.startsWith(SUPA+'/rest/v1/rpc/get_contacts_v2')){event.respondWith(fallbackGetContactsV2(req).catch(()=>fetch(req)));return;}
  if(req.method!=='GET')return;
  event.respondWith(fetch(req).catch(()=>caches.match(req)));
});
