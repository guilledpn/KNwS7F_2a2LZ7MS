(function bootstrapStorage(global) {
  'use strict';

  const namespace = global.AppDev = global.AppDev || {};
  const environment = namespace.environment;
  if (!environment) throw new Error('Storage DEV requiere environment.js');

  const prefix = environment.storageNamespace;
  const legacyPrefix = 'recovery_crm_dev_';

  function resolveKey(name) {
    const key = String(name || '');
    if (!key) throw new Error('Clave de almacenamiento vacía');
    if (key.startsWith(prefix) || key.startsWith(legacyPrefix)) return key;
    return prefix + key;
  }

  function getRaw(name, fallback = null) {
    try {
      const value = global.localStorage.getItem(resolveKey(name));
      return value === null ? fallback : value;
    } catch (error) {
      namespace.errors && namespace.errors.report(error, { source: 'storage.getRaw', key: String(name) });
      return fallback;
    }
  }

  function setRaw(name, value) {
    try {
      global.localStorage.setItem(resolveKey(name), String(value));
      return true;
    } catch (error) {
      namespace.errors && namespace.errors.report(error, { source: 'storage.setRaw', key: String(name) });
      return false;
    }
  }

  function removeRaw(name) {
    try {
      global.localStorage.removeItem(resolveKey(name));
      return true;
    } catch (error) {
      namespace.errors && namespace.errors.report(error, { source: 'storage.removeRaw', key: String(name) });
      return false;
    }
  }

  function getJSON(name, fallback = null) {
    const raw = getRaw(name, null);
    if (raw === null) return fallback;
    try {
      return JSON.parse(raw);
    } catch (error) {
      namespace.errors && namespace.errors.report(error, { source: 'storage.getJSON', key: String(name) });
      return fallback;
    }
  }

  function setJSON(name, value) {
    try {
      return setRaw(name, JSON.stringify(value));
    } catch (error) {
      namespace.errors && namespace.errors.report(error, { source: 'storage.setJSON', key: String(name) });
      return false;
    }
  }

  namespace.storage = Object.freeze({
    namespace: prefix,
    resolveKey,
    getRaw,
    setRaw,
    removeRaw,
    getJSON,
    setJSON
  });
})(window);
