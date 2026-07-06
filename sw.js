const APP_VERSION='crm-llamados-github-wrapper-v76-contactos-test';
const APP_CACHE=APP_VERSION+'-shell';
const SHELL_ASSETS=['./','./index.html','./manifest.webmanifest','./icons/icon.svg','./assets/logo-horizontal.svg'];
const SUPA='https://ojaimqutuycralrjbxwr.supabase.co';
const APP_SOURCE_PREFIX=SUPA+'/storage/v1/object/public/pwa/index.html';
const ACTIVE_PERIOD='2026-06';
const REAL_MONTHS=[
  {period:'2026-06',rows:89948,distinct_ruts:89948},
  {period:'2026-05',rows:95608,distinct_ruts:95607},
  {period:'2026-04',rows:65275,distinct_ruts:65275},
  {period:'2026-03',rows:67241,distinct_ruts:67241},
  {period:'2026-02',rows:72758,distinct_ruts:72758}
];
const DEFAULT_TOTAL=25840;
const DEFAULT_PENDING=25755;
const DEFAULT_ASSIGNED=234;
self.addEventListener('install',event=>{self.skipWaiting();event.waitUntil(caches.open(APP_CACHE).then(cache=>cache.addAll(SHELL_ASSETS)).catch(()=>null));});
self.addEventListener('message',event=>{if(event.data&&event.data.type==='SKIP_WAITING')self.skipWaiting();});
self.addEventListener('activate',event=>{event.waitUntil((async()=>{const keys=await caches.keys();await Promise.all(keys.filter(key=>key!==APP_CACHE).map(key=>caches.delete(key)));await self.clients.claim();const wins=await self.clients.matchAll({type:'window',includeUncontrolled:true});await Promise.all(wins.map(client=>{try{const u=new URL(client.url);if(u.searchParams.get('_swv')!==APP_VERSION){u.searchParams.set('_swv',APP_VERSION);return client.navigate(u.href);}}catch(e){}return Promise.resolve();}));})());});
function copyHeaders(req){const o={};['apikey','authorization','x-client-info'].forEach(k=>{const v=req.headers.get(k);if(v)o[k]=v;});o.accept='application/json';return o;}
function okJson(obj){return new Response(JSON.stringify(obj),{status:200,headers:{'content-type':'application/json; charset=utf-8','access-control-allow-origin':'*'}})}
function pgList(vals){return '('+vals.map(v=>'"'+String(v).replace(/"/g,'')+'"').join(',')+')'}
function pgArray(vals){return '{'+vals.map(v=>String(v).replace(/[{}]/g,'')).join(',')+'}'}
function enc(s){return encodeURIComponent(String(s));}
function monthInfo(p){const realSet=new Set(REAL_MONTHS.map(m=>m.period));const raw=(Array.isArray(p.p_months)?p.p_months.filter(Boolean):[]);const months=raw.filter(m=>realSet.has(m));const allReal=REAL_MONTHS.every(m=>raw.includes(m.period));return{raw,months,allReal};}
function patchAppHtml(html){return html.split('<div class="top-title" id="main-title">Contactos</div>').join('<div class="top-title" id="main-title">Contactos test</div>').split("contacts:'Contactos',stats:'Stats',import:'Importar'").join("contacts:'Contactos test',stats:'Stats',import:'Importar'");}
async function patchAppSource(req){const res=await fetch(req,{cache:'no-store'});const html=await res.text();const headers=new Headers(res.headers);headers.set('content-type','text/html; charset=utf-8');headers.set('cache-control','no-store');return new Response(patchAppHtml(html),{status:res.status,statusText:res.statusText,headers});}
async function exactCount(path,headers){const r=await fetch(SUPA+path,{method:'GET',headers:{...headers,'prefer':'count=exact'},mode:'cors'});const cr=r.headers.get('content-range')||'';const m=cr.match(/\/(\d+)$/);return m?Number(m[1]):0;}
function buildConds(p){
  const situation=p.p_situation||'gestionables';
  const search=String(p.p_search||'').trim().toLowerCase();
  const mi=monthInfo(p);
  const months=mi.months;
  const types=Array.isArray(p.p_types)?p.p_types.filter(Boolean):[];
  const monthMode=p.p_month_mode||'any';
  const cond=[];
  cond.push('active_period=eq.'+enc(ACTIVE_PERIOD));
  if(situation==='gestionables')cond.push('gestionable_actual=eq.true');
  else if(situation==='no_gestionables'||situation==='no-gestionables')cond.push('gestionable_actual=eq.false');
  if(types.length===1&&types[0]==='asignado')cond.push('motivo_gestionabilidad=eq.asignado');
  else if(types.length===1&&types[0]==='regla')cond.push('motivo_gestionabilidad=eq.disponible_por_regla');
  else if(types.length>1)cond.push('motivo_gestionabilidad=in.(asignado,disponible_por_regla)');
  if(p.p_pending_only)cond.push('estado_gestion=eq.Pendiente');
  if(p.p_assigned_only)cond.push('motivo_gestionabilidad=eq.asignado');
  if(search)cond.push('search_text=like.*'+enc(search.replace(/[*]/g,''))+'*');
  if(months.length&&!mi.allReal){
    if(monthMode==='all')cond.push('meses_aparicion=cs.'+enc(pgArray(months)));
    else if(monthMode==='only'){cond.push('meses_aparicion=cs.'+enc(pgArray(months)));cond.push('meses_aparicion=cd.'+enc(pgArray(months)));}
    else cond.push('meses_aparicion=ov.'+enc(pgArray(months)));
  }else if(mi.raw.length&&!mi.allReal){
    cond.push('rut_norm=eq.__no_real_month_selected__');
  }
  return cond;
}
async function fallbackGetContactsV2(req){
  let body={};try{body=await req.clone().json();}catch(e){}
  const p=body||{};
  const limit=Math.max(1,Math.min(Number(p.p_limit||50),200));
  const offset=Math.max(0,Number(p.p_offset||0));
  const headers=copyHeaders(req);
  const cond=buildConds(p);
  const baseCond=cond.join('&');
  const select='active_period,contact_id,rut_norm,work_item_id,campaign_key,campaign_name,campaign_desc,estado_gestion,fecha_estado_gestion,ingreso_estimado,comentarios,recordatorio_titulo,recordatorio_fecha_hora,ultimo_contacto,meses_aparicion,ultimo_mes_observado,ultimo_estado_observado,aparece_en_campana_activa,asignado_a_mi,gestionable_actual,motivo_gestionabilidad,display_order';
  const order='order=motivo_gestionabilidad.asc.nullslast&order=display_order.asc.nullslast&order=rut_norm.asc';
  const q='/rest/v1/contact_operational_state_v2?select='+select+'&'+baseCond+'&'+order+'&limit='+limit+'&offset='+offset;
  const mi=monthInfo(p);
  const noMonthFilter=!mi.raw.length||mi.allReal;
  const isDefault=(p.p_situation||'gestionables')==='gestionables'&&!String(p.p_search||'').trim()&&noMonthFilter&&!(Array.isArray(p.p_types)&&p.p_types.length)&&!p.p_pending_only&&!p.p_assigned_only;
  const totalPromise=isDefault?Promise.resolve(DEFAULT_TOTAL):exactCount('/rest/v1/contact_operational_state_v2?select=rut_norm&'+baseCond+'&limit=1',headers);
  const [baseRows,total]=await Promise.all([fetch(SUPA+q,{headers,mode:'cors'}).then(r=>{if(!r.ok)throw new Error('contacts fallback base '+r.status);return r.json();}),totalPromise]);
  const ruts=[...new Set(baseRows.map(x=>x.rut_norm).filter(Boolean))];
  let contactMap={};
  if(ruts.length){
    const cq='/rest/v1/contacts?select=contact_id,rut_norm,rut,nombre,telefono_1,telefono_2,telefono_3,email,telefono_activo_idx&rut_norm=in.'+encodeURIComponent(pgList(ruts));
    const cs=await fetch(SUPA+cq,{headers,mode:'cors'}).then(r=>r.ok?r.json():[]);
    cs.forEach(c=>{contactMap[c.rut_norm]=c;});
  }
  const rows=baseRows.map(x=>{const c=contactMap[x.rut_norm]||{};return {...x,contact_id:c.contact_id||x.contact_id,rut:c.rut||x.rut_norm,nombre:c.nombre||'',telefono_1:c.telefono_1||'',telefono_2:c.telefono_2||'',telefono_3:c.telefono_3||'',telefono_activo_idx:c.telefono_activo_idx??null,email:c.email||'',motivo_label:x.motivo_gestionabilidad==='asignado'?'Asignado':(x.motivo_gestionabilidad==='disponible_por_regla'?'Disponible por regla':(x.motivo_gestionabilidad==='campana_activa_no_asignado'?'Campaña activa no asignado':(x.motivo_gestionabilidad==='historico_gestionado'?'Histórico gestionado':'Histórico informativo')))};});
  return okJson({ok:true,source:'lite_v76_contactos_test',active_period:ACTIVE_PERIOD,limit,offset,base_total:Number(total||0),base_pending:isDefault?DEFAULT_PENDING:Number(total||0),base_assigned:isDefault?DEFAULT_ASSIGNED:0,base_gestionables:isDefault?DEFAULT_TOTAL:Number(total||0),base_no_gestionables:0,result_total:Number(total||0),rows});
}
self.addEventListener('fetch',event=>{
  const req=event.request;
  if(req.method==='GET'&&req.url.startsWith(APP_SOURCE_PREFIX)){event.respondWith(patchAppSource(req).catch(()=>fetch(req)));return;}
  if(req.method==='POST'&&req.url.startsWith(SUPA+'/rest/v1/rpc/get_contacts_v2_months')){event.respondWith(okJson({ok:true,source:'lite_v76_contactos_test',months:REAL_MONTHS}));return;}
  if(req.method==='POST'&&req.url.startsWith(SUPA+'/rest/v1/rpc/get_contacts_v2')){event.respondWith(fallbackGetContactsV2(req).catch(()=>fetch(req)));return;}
  if(req.method!=='GET')return;
  event.respondWith(fetch(req).catch(()=>caches.match(req)));
});
