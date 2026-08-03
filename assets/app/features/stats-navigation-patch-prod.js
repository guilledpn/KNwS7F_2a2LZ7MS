(function installProdStatsNavigationPatch(global){
  'use strict';

  const PATCH_ID='UI-20260803-03';
  let installed=false;
  let screenBeforeStats='contacts';

  const byId=id=>document.getElementById(id);

  function ensureBackButton(){
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
      button.style.flex='0 0 44px';
      button.innerHTML='<svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24" aria-hidden="true"><path d="M15 18 9 12l6-6"/></svg>';
      topbar.insertBefore(button,title);
    }

    button.onclick=()=>{
      const target=screenBeforeStats&&screenBeforeStats!=='stats'
        ?screenBeforeStats
        :'contacts';
      global.setScreen(target);
    };
    return button;
  }

  function syncBackButton(screen){
    const button=ensureBackButton();
    if(button)button.style.display=screen==='stats'?'grid':'none';
  }

  function install(){
    if(installed)return;
    if(typeof global.setScreen!=='function'){
      setTimeout(install,50);
      return;
    }

    if(global.CRM_STATS_NAVIGATION_PATCH===PATCH_ID){
      installed=true;
      return;
    }

    const originalSetScreen=global.setScreen;
    global.setScreen=function patchedSetScreen(screen,button){
      if(screen==='stats'&&typeof currentScreen!=='undefined'&&currentScreen!=='stats'){
        screenBeforeStats=currentScreen||'contacts';
      }
      const result=originalSetScreen.call(this,screen,button);
      syncBackButton(screen);
      return result;
    };

    ensureBackButton();
    syncBackButton(typeof currentScreen!=='undefined'?currentScreen:'contacts');
    global.CRM_STATS_NAVIGATION_PATCH=PATCH_ID;
    installed=true;
  }

  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',install,{once:true});
  else install();
})(window);
