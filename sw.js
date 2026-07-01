const APP_VERSION='crm-ffvv-github-wrapper-v2';
const APP_CACHE=APP_VERSION+'-shell';
const SHELL_ASSETS=['./','./index.html','./manifest.webmanifest','./icons/icon.svg'];
self.addEventListener('install',event=>{self.skipWaiting();event.waitUntil(caches.open(APP_CACHE).then(cache=>cache.addAll(SHELL_ASSETS)).catch(()=>null));});
self.addEventListener('activate',event=>{event.waitUntil((async()=>{const keys=await caches.keys();await Promise.all(keys.filter(key=>key!==APP_CACHE).map(key=>caches.delete(key)));await self.clients.claim();})());});
self.addEventListener('fetch',event=>{const req=event.request;if(req.method!=='GET')return;event.respondWith(caches.match(req).then(cached=>cached||fetch(req)));});
