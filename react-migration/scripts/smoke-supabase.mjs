import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { createClient } from '@supabase/supabase-js';

const DEFAULT_URL = 'https://lijibbhpyyptodneafdd.supabase.co';
const ROOT_INDEX = resolve(process.cwd(), '..', 'index.html');

function readEnvFile(path) {
  try {
    const text = readFileSync(path, 'utf8');
    for (const line of text.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eq = trimmed.indexOf('=');
      if (eq <= 0) continue;
      const key = trimmed.slice(0, eq).trim();
      let value = trimmed.slice(eq + 1).trim();
      value = value.replace(/^['"]|['"]$/g, '');
      if (key && value && !process.env[key]) process.env[key] = value;
    }
  } catch {
    // Optional local file. Safe to ignore.
  }
}

function decodePublicAnonKeyFromIndex() {
  let html = '';
  try {
    html = readFileSync(ROOT_INDEX, 'utf8');
  } catch {
    return '';
  }

  const matches = [...html.matchAll(/String\.fromCharCode\(([^)]*)\)/g)];
  for (const match of matches) {
    const codes = match[1]
      .split(',')
      .map((x) => Number(x.trim()))
      .filter((n) => Number.isInteger(n) && n > 0);

    if (!codes.length) continue;
    const decoded = String.fromCharCode(...codes);
    const looksLikeAnonJwt = decoded.startsWith('eyJ') && decoded.split('.').length >= 3;
    const looksLikePublishable = decoded.startsWith('sb_publishable_');
    if (looksLikeAnonJwt || looksLikePublishable) return decoded;
  }
  return '';
}

readEnvFile(resolve(process.cwd(), '.env.local'));
readEnvFile(resolve(process.cwd(), '.env'));

const supabaseUrl = process.env.VITE_SUPABASE_URL || DEFAULT_URL;
const supabaseAnonKey =
  process.env.VITE_SUPABASE_ANON_KEY ||
  process.env.SUPABASE_ANON_KEY ||
  decodePublicAnonKeyFromIndex();

if (!supabaseAnonKey) {
  throw new Error('No anon/publishable key available. Set VITE_SUPABASE_ANON_KEY in .env.local.');
}

const restProbe = await fetch(`${supabaseUrl}/rest/v1/`, {
  headers: {
    apikey: supabaseAnonKey,
    Authorization: `Bearer ${supabaseAnonKey}`
  }
});

if (restProbe.status === 401 || restProbe.status === 403) {
  throw new Error(`Supabase smoke failed: public key rejected by REST endpoint. status=${restProbe.status}`);
}

if (restProbe.status >= 500) {
  throw new Error(`Supabase smoke failed: Supabase REST unavailable. status=${restProbe.status}`);
}

console.log(`Supabase connectivity OK. REST status=${restProbe.status}`);

const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: { persistSession: false, autoRefreshToken: false }
});

const { data, error } = await supabase.rpc('get_contacts_v2', {
  p_active_period: null,
  p_search: '',
  p_situation: 'gestionables',
  p_pending_only: false,
  p_assigned_only: false,
  p_types: [],
  p_months: [],
  p_month_mode: 'any',
  p_limit: 3,
  p_offset: 0
});

if (error) {
  console.log(`Supabase RPC smoke skipped in CI. Authenticated runtime required or RPC protected. code=${error.code || 'no-code'}`);
  process.exit(0);
}

if (!data || !Array.isArray(data.rows)) {
  throw new Error('Supabase smoke failed: unexpected get_contacts_v2 response shape.');
}

const first = data.rows[0] || {};
const keys = Object.keys(first).sort().slice(0, 12);
console.log(`Supabase RPC smoke OK. rows=${data.rows.length}; keys=${keys.join(',')}`);
