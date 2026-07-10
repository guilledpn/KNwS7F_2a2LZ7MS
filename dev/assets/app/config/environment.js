(function bootstrapEnvironment(global) {
  'use strict';

  const namespace = global.AppDev = global.AppDev || {};
  const environment = Object.freeze({
    appEnv: 'DEV',
    appName: 'APP LLAMADOS DEV',
    appVersion: 'v1.05',
    buildId: '15aedf75b82d',
    supabaseProject: 'crm-ffvv-dev',
    supabaseProjectRef: 'xcujixexjbuqqzlbomgw',
    supabaseUrl: 'https://xcujixexjbuqqzlbomgw.supabase.co',
    supabasePublishableKey: 'sb_publishable_eCchzuWGoCSl_Vnvyv_cYg_0A2CTDK8',
    pageSize: 50,
    contactsCacheVersion: 'v2_space_safe_2026_07_restore_v62',
    storageNamespace: 'crm_ffvv_dev_',
    legacySprintKey: 'recovery_crm_dev_20260709_sprint_v2',
    macroDroidUrl: '',
    tasksWebhookUrl: '',
    externalIntegrationsEnabledByDefault: false,
    serviceWorkerUrl: './sw.js',
    serviceWorkerScope: './'
  });

  if (environment.appEnv !== 'DEV' || environment.supabaseProjectRef !== 'xcujixexjbuqqzlbomgw') {
    throw new Error('Bloqueo de seguridad: configuración DEV inválida');
  }
  if (environment.supabaseUrl.indexOf('lijibbhpyyptodneafdd') !== -1) {
    throw new Error('Bloqueo de seguridad: DEV contiene el endpoint de PROD');
  }
  if (global.location && !global.location.pathname.includes('/dev/')) {
    throw new Error('Bloqueo de seguridad: la aplicación DEV está fuera de /dev/');
  }

  Object.defineProperty(namespace, 'environment', {
    value: environment,
    enumerable: true,
    configurable: false,
    writable: false
  });
})(window);
