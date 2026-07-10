(function bootstrapAuth(global) {
  'use strict';

  const namespace = global.AppDev = global.AppDev || {};
  if (!namespace.supabase) throw new Error('Auth DEV requiere supabase-client.js');

  function client() {
    return namespace.supabase.getClient();
  }

  async function getSession() {
    const { data, error } = await client().auth.getSession();
    if (error) throw namespace.errors.normalize(error, { source: 'auth.getSession' });
    return data && data.session ? data.session : null;
  }

  async function signIn(email, password) {
    const { data, error } = await client().auth.signInWithPassword({ email, password });
    if (error) throw namespace.errors.normalize(error, { source: 'auth.signIn' });
    return data;
  }

  async function signInWithOtp(email) {
    const { data, error } = await client().auth.signInWithOtp({ email });
    if (error) throw namespace.errors.normalize(error, { source: 'auth.signInWithOtp' });
    return data;
  }

  async function signOut() {
    const { error } = await client().auth.signOut();
    if (error) throw namespace.errors.normalize(error, { source: 'auth.signOut' });
  }

  function onChange(callback) {
    const result = client().auth.onAuthStateChange((event, session) => callback(event, session));
    return result && result.data ? result.data.subscription : null;
  }

  namespace.auth = Object.freeze({
    isConfigured: namespace.supabase.isConfigured,
    getSession,
    signIn,
    signInWithOtp,
    signOut,
    onChange
  });
})(window);
