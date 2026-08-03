(function installProdCanonicalTopbarPatch(global){
  'use strict';

  const PATCH_ID='UI-20260803-07';
  const SECONDARY_SCREENS=new Set(['stats','import']);
  const historyStack=[];
  let installed=false;
  let restoring=false;
  let pendingDetailContext=null;

  const byId=id=>document.getElementById(id);
  const currentMainScreen=()=>typeof currentScreen!=='undefined'&&currentScreen
    ?currentScreen
    :'contacts';

  function ensureCanonicalStyles(){
    if(byId('crm-canonical-topbar-style'))return;
    const style=document.createElement('style');
    style.id='crm-canonical-topbar-style';
    style.textContent=`
#main-topbar.crm-has-context-back{padding-left:8px!important}
#stats-back-btn{flex:0 0 44px!important}
.detail-top #crm-sprint-chip-detail{margin-left:auto!important}
.detail-top .detail-goal{margin-left:0!important}
`;
    document.head.appendChild(style);
  }

  function rowIdentity(row){
    return {
      contactId:row?.contact_id||null,
      workItemId:row?.work_item_id||null
    };
  }

  function captureDetailContext(){
    const detail=byId('detail');
    if(!detail?.classList.contains('on'))return null;
    if(typeof detailIndex==='undefined'||detailIndex<0)return null;

    const rows=typeof filtered!=='undefined'&&Array.isArray(filtered)?filtered:[];
    const row=rows[detailIndex]||null;
    const identity=rowIdentity(row);
    return {
      kind:'detail',
      index:detailIndex,
      contactId:identity.contactId,
      workItemId:identity.workItemId,
      scrollTop:Number(byId('detail-scroll')?.scrollTop||0)
    };
  }

  function captureDetailOrigin(event){
    if(!event.target?.closest?.('.detail-goal'))return;
    const context=captureDetailContext();
    if(!context)return;

    pendingDetailContext=context;
    setTimeout(()=>{
      if(pendingDetailContext===context)pendingDetailContext=null;
    },0);
  }

  function sameContext(a,b){
    if(!a||!b||a.kind!==b.kind)return false;
    if(a.kind==='screen')return a.screen===b.screen;
    return Boolean(
      (a.workItemId&&a.workItemId===b.workItemId)||
      (a.contactId&&a.contactId===b.contactId)
    );
  }

  function pushContext(context){
    if(!context)return;
    const last=historyStack[historyStack.length-1];
    if(sameContext(last,context))return;
    historyStack.push(context);
    if(historyStack.length>20)historyStack.shift();
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

  function restoreContext(context){
    const target=context||{kind:'screen',screen:'contacts'};
    restoring=true;
    try{
      if(target.kind==='detail'){
        global.setScreen('contacts');
        const index=resolveDetailIndex(target);
        if(index>=0&&typeof global.openDetail==='function'){
          global.openDetail(index);
          requestAnimationFrame(()=>requestAnimationFrame(()=>{
            const scroll=byId('detail-scroll');
            if(scroll)scroll.scrollTop=target.scrollTop||0;
          }));
        }
        return;
      }

      const screen=SECONDARY_SCREENS.has(target.screen)||target.screen==='contacts'
        ?target.screen
        :'contacts';
      global.setScreen(screen);
    }finally{
      restoring=false;
    }
  }

  function goBack(){
    restoreContext(historyStack.pop()||{kind:'screen',screen:'contacts'});
  }

  function interceptBack(event){
    if(!event.target?.closest?.('#stats-back-btn'))return;
    event.preventDefault();
    event.stopImmediatePropagation();
    goBack();
  }

  function ensureBackButton(){
    ensureCanonicalStyles();
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
    button.onclick=goBack;
    return button;
  }

  function syncTopbar(screen){
    const button=ensureBackButton();
    const topbar=byId('main-topbar');
    const show=SECONDARY_SCREENS.has(screen);
    if(button)button.style.display=show?'grid':'none';
    if(topbar)topbar.classList.toggle('crm-has-context-back',show);
  }

  function install(){
    if(installed)return;
    ensureCanonicalStyles();

    if(typeof global.setScreen!=='function'){
      setTimeout(install,50);
      return;
    }

    if(global.CRM_CANONICAL_TOPBAR_PATCH===PATCH_ID){
      syncTopbar(currentMainScreen());
      installed=true;
      return;
    }

    const previousSetScreen=global.setScreen;
    global.setScreen=function canonicalSetScreen(screen,button){
      const from=currentMainScreen();

      if(!restoring&&screen!==from){
        if(SECONDARY_SCREENS.has(screen)){
          pushContext(pendingDetailContext||{kind:'screen',screen:from});
          pendingDetailContext=null;
        }else if(screen==='contacts'){
          historyStack.length=0;
          pendingDetailContext=null;
        }
      }

      const result=previousSetScreen.call(this,screen,button);
      syncTopbar(screen);
      return result;
    };

    document.addEventListener('click',captureDetailOrigin,true);
    document.addEventListener('click',interceptBack,true);
    ensureBackButton();
    syncTopbar(currentMainScreen());

    global.CRM_CANONICAL_TOPBAR_PATCH=PATCH_ID;
    global.CRM_STATS_NAVIGATION_PATCH=PATCH_ID;
    installed=true;
  }

  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',install,{once:true});
  else install();
})(window);
