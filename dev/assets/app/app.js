(function bootstrapAppDev(global) {
  'use strict';

  const namespace = global.AppDev = global.AppDev || {};
  const required = ['environment', 'errors', 'storage', 'supabase', 'auth', 'pwa'];
  const missing = required.filter(name => !namespace[name]);
  if (missing.length) {
    throw new Error('APP LLAMADOS DEV: faltan módulos: ' + missing.join(', '));
  }

  namespace.errors.installGlobalHandlers();
  namespace.pwa.register();

  Object.defineProperty(namespace, 'ready', {
    value: true,
    enumerable: true,
    configurable: false,
    writable: false
  });

  try {
    global.dispatchEvent(new CustomEvent('appdev:ready', {
      detail: {
        environment: namespace.environment.appEnv,
        buildId: namespace.environment.buildId,
        supabaseProject: namespace.environment.supabaseProject
      }
    }));
  } catch (_) {}
})(window);
