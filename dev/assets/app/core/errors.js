(function bootstrapErrors(global) {
  'use strict';

  const namespace = global.AppDev = global.AppDev || {};
  const history = [];
  const MAX_HISTORY = 40;

  class AppError extends Error {
    constructor(message, options) {
      super(message || 'Error de aplicación');
      this.name = 'AppError';
      this.code = options && options.code ? options.code : 'APP_ERROR';
      this.context = options && options.context ? options.context : {};
      this.cause = options && options.cause ? options.cause : null;
    }
  }

  function normalize(error, context) {
    if (error instanceof AppError) return error;
    const message = error && error.message ? error.message : String(error || 'Error desconocido');
    return new AppError(message, {
      code: error && error.code ? String(error.code) : 'UNEXPECTED_ERROR',
      context: context || {},
      cause: error || null
    });
  }

  function report(error, context) {
    const normalized = normalize(error, context);
    const entry = Object.freeze({
      at: new Date().toISOString(),
      code: normalized.code,
      message: normalized.message,
      context: normalized.context
    });
    history.push(entry);
    if (history.length > MAX_HISTORY) history.shift();
    console.error('[APP LLAMADOS DEV]', normalized);
    try {
      global.dispatchEvent(new CustomEvent('appdev:error', { detail: entry }));
    } catch (_) {}
    return normalized;
  }

  function installGlobalHandlers() {
    if (namespace.__globalErrorHandlersInstalled) return;
    namespace.__globalErrorHandlersInstalled = true;
    global.addEventListener('error', event => {
      report(event.error || event.message, { source: 'window.error' });
    });
    global.addEventListener('unhandledrejection', event => {
      report(event.reason, { source: 'unhandledrejection' });
    });
  }

  namespace.errors = Object.freeze({
    AppError,
    normalize,
    report,
    installGlobalHandlers,
    history: () => history.slice()
  });
})(window);
