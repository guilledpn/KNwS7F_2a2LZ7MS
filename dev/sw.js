'use strict';
const CACHE_NAME='app-llamados-dev-lcd-20260713-01-stats';
const SHELL=['./','./index.html','./manifest.webmanifest','./icons/icon.svg','./icons/icon-192.png','./icons/icon-512.png'];
const MODULE_SHELL=[
  './assets/app/config/environment.js',
  './assets/app/core/errors.js',
  './assets/app/core/storage.js',
  './assets/app/core/supabase-client.js',
  './assets/app/core/auth.js',
  './assets/app/core/pwa.js',
  './assets/app/app.js',
  './assets/app/features/stats-metrics-patch.js'
];

self.addEventListener('install',event=>{
  self.skipWaiting();
  event.waitUntil(caches.open(CACHE_NAME).then(cache=>cache.addAll(SHELL.concat(MODULE_SHELL))));
});

self.addEventListener('activate',event=>{
  event.waitUntil((async()=>{
    const keys=await caches.keys();
    await Promise.all(keys.filter(key=>key.startsWith('app-llamados-dev-')&&key!==CACHE_NAME).map(key=>caches.delete(key)));
    await self.clients.claim();
    const clients=await self.clients.matchAll({type:'window',includeUncontrolled:true});
    await Promise.all(clients.map(client=>{
      try{
        const url=new URL(client.url);
        if(url.searchParams.get('_devsw')!=='LCD-20260713-01'){
          url.searchParams.set('_devsw','LCD-20260713-01');
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
  const url=new URL(req.url);
  if(url.origin!==self.location.origin)return;
  if(req.mode==='navigate'){
    event.respondWith(fetch(req).then(res=>{
      const copy=res.clone();
      caches.open(CACHE_NAME).then(cache=>cache.put('./index.html',copy));
      return res;
    }).catch(()=>caches.match('./index.html')));
    return;
  }
  event.respondWith(caches.match(req).then(hit=>hit||fetch(req)));
});
