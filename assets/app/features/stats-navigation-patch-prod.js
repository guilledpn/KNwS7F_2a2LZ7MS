(function installProdStatsNavigationPatch(global){
  'use strict';

  const PATCH_ID='UI-20260803-06';
  const DETAIL_RETURN_PATCH_ID='UI-20260803-06-detail';
  let installed=false;
  let screenBeforeStats='contacts';
  let detailReturnContext=null;

  const byId=id=>document.getElementById(id);

  function rowIdentity(row){
    return {
      contactId:row?.contact_id||null,
      workItemId:row?.work_item_id||null
    };
  }

  function captureDetailOrigin(event){
    const trigger=event.target?.closest?.('.detail-goal');
    if(!trigger)return;
    const detail=byId('detail');
    if(!detail?.classList.contains('on'))return;
    if(typeof detailIndex==='undefined'||detailIndex<0)return;

    const rows=typeof filtered!=='undefined'&&Array.isArray(filtered)?filtered:[];
    const row=rows[detailIndex]||null;
    const identity=rowIdentity(row);
    detailReturnContext={
      index:detailIndex,
      contactId:identity.contactId,
      workItemId:identity.workItemId,
      scrollTop:Number(byId('detail-scroll')?.scrollTop||0)
    };
  }

  function resolveDetailIndex(context){
    const rows=typeof filtered!=='undefined'&&Array.isArray(filtered)?filtered:[];
    let index=-1;
    if(context.workItemId){
      index=rows.findIndex(row=>row?.work_item_id===context.workItemId);
    }
    if(index<0&&context.contactId){
      index=rows.findIndex(row=>row?.contact_id===context.contactId);
    }
    if(index<0&&Number.isInteger(context.index)&&context.index>=0&&context.index<rows.length){
      index=context.index;
    }
    return index;
  }

  function restoreDetail(context){
    global.setScreen('contacts');
    const index=resolveDetailIndex(context);
    if(index<0||typeof global.openDetail!=='function')return;

    global.openDetail(index);
    requestAnimationFrame(()=>requestAnimationFrame(()=>{
      const scroll=byId('detail-scroll');
      if(scroll)scroll.scrollTop=context.scrollTop||0;
    }));
  }

  function interceptStatsBack(event){
    const back=event.target?.closest?.('#stats-back-btn');
    if(!back||!detailReturnContext)return;

    event.preventDefault();
    event.stopImmediatePropagation();
    const context=detailReturnContext;
    detailReturnContext=null;
    restoreDetail(context);
  }

  function installDetailReturnFix(){
    if(global.CRM_STATS_DETAIL_RETURN_PATCH===DETAIL_RETURN_PATCH_ID)return;
    document.addEventListener('click',captureDetailOrigin,true);
    document.addEventListener('click',interceptStatsBack,true);
    global.CRM_STATS_DETAIL_RETURN_PATCH=DETAIL_RETURN_PATCH_ID;
  }

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
      button.innerHTML='<svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24" aria-hidden="true"><path d="M15 18 9 12l6-6"/></svg>';
      topbar.insertBefore(button,title);
    }
    button.style.flex='0 0 44px';

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
    installDetailReturnFix();

    if(typeof global.setScreen!=='function'){
      setTimeout(install,50);
      return;
    }

    if(global.CRM_STATS_NAVIGATION_PATCH){
      ensureBackButton();
      syncBackButton(typeof currentScreen!=='undefined'?currentScreen:'contacts');
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
