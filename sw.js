const APP_VERSION='App_llamados_v1.05-ui-20260804-09';
const PATCH_ID='UI-20260804-09';
const METRICS_PATCH_ID='UI-20260804-09';
const METRICS_PATCH_TAG='<script src="./assets/app/features/stats-metrics-patch-prod.js?v='+METRICS_PATCH_ID+'" data-crm-stats-metrics-patch="'+METRICS_PATCH_ID+'"></script>';
const NAVIGATION_PATCH_TAG='<script src="./assets/app/features/stats-navigation-patch-prod.js?v='+PATCH_ID+'" data-crm-stats-navigation-patch="'+PATCH_ID+'"></script>';

self.addEventListener('install',event=>{
  self.skipWaiting();
});

self.addEventListener('activate',event=>{
  event.waitUntil((async()=>{
    const keys=await caches.keys();
    await Promise.all(keys.map(key=>caches.delete(key)));
    await self.clients.claim();
    const clients=await self.clients.matchAll({type:'window',includeUncontrolled:true});
    await Promise.all(clients.map(client=>{
      try{
        const url=new URL(client.url);
        if(url.searchParams.get('_prodpatch')!==PATCH_ID){
          url.searchParams.set('_prodpatch',PATCH_ID);
          return client.navigate(url.href);
        }
      }catch(_){ }
      return Promise.resolve();
    }));
  })());
});

self.addEventListener('fetch',event=>{
  const req=event.request;
  if(req.method!=='GET')return;

  if(req.mode==='navigate'){
    event.respondWith((async()=>{
      const response=await fetch(req,{cache:'no-store'});
      const contentType=response.headers.get('content-type')||'';
      if(!response.ok||!contentType.includes('text/html'))return response;

      let html=await response.text();
      if(!html.includes('stats-metrics-patch-prod.js')){
        html=html.replace('</body>',METRICS_PATCH_TAG+'</body>');
      }
      if(!html.includes('stats-navigation-patch-prod.js')){
        html=html.replace('</body>',NAVIGATION_PATCH_TAG+'</body>');
      }

      const headers=new Headers(response.headers);
      headers.delete('content-length');
      headers.delete('content-encoding');
      headers.delete('etag');
      headers.set('cache-control','no-store');

      return new Response(html,{
        status:response.status,
        statusText:response.statusText,
        headers
      });
    })().catch(()=>fetch(req,{cache:'no-store'})));
    return;
  }

  event.respondWith(fetch(req,{cache:'no-store'}).catch(()=>caches.match(req)));
});
