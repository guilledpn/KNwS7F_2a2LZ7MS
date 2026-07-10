(function bootstrapSupabaseClient(global) {
  'use strict';

  const namespace = global.AppDev = global.AppDev || {};
  const environment = namespace.environment;
  if (!environment) throw new Error('Supabase DEV requiere environment.js');

  let client = null;

  function isConfigured() {
    return /^https:\/\//.test(environment.supabaseUrl) &&
      environment.supabaseProjectRef === 'xcujixexjbuqqzlbomgw' &&
      environment.supabasePublishableKey.startsWith('sb_publishable_');
  }

  function getClient() {
    if (client) return client;
    if (!isConfigured()) {
      throw new namespace.errors.AppError('Configuración Supabase DEV inválida', {
        code: 'DEV_SUPABASE_CONFIG_INVALID'
      });
    }
    if (!global.supabase || typeof global.supabase.createClient !== 'function') {
      throw new namespace.errors.AppError('Supabase JS no está disponible', {
        code: 'SUPABASE_LIBRARY_MISSING'
      });
    }
    client = global.supabase.createClient(
      environment.supabaseUrl,
      environment.supabasePublishableKey,
      {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true
        }
      }
    );
    return client;
  }

  namespace.supabase = Object.freeze({
    isConfigured,
    getClient,
    projectRef: environment.supabaseProjectRef
  });
})(window);
