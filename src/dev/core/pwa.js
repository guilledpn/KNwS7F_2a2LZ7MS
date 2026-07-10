(function bootstrapPwa(global) {
  'use strict';

  const namespace = global.AppDev = global.AppDev || {};
  const environment = namespace.environment;
  if (!environment) throw new Error('PWA DEV requiere environment.js');

  let registrationPromise = null;

  function register() {
    if (!('serviceWorker' in navigator)) return Promise.resolve(null);
    if (registrationPromise) return registrationPromise;
    registrationPromise = navigator.serviceWorker
      .register(environment.serviceWorkerUrl, { scope: environment.serviceWorkerScope })
      .catch(error => {
        namespace.errors && namespace.errors.report(error, { source: 'pwa.register' });
        return null;
      });
    return registrationPromise;
  }

  namespace.pwa = Object.freeze({ register });
})(window);
