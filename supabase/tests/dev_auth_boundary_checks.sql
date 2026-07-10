-- APP LLAMADOS · DEV security checks
-- Read-only assertions. Run in the Supabase SQL editor as database owner.

DO $$
DECLARE
  failures text[] := ARRAY[]::text[];
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
      AND NOT c.relrowsecurity
  ) THEN
    failures := array_append(failures, 'Hay tablas public sin RLS');
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
      AND has_table_privilege('anon', c.oid, 'SELECT,INSERT,UPDATE,DELETE')
  ) THEN
    failures := array_append(failures, 'anon conserva privilegios DML en tablas public');
  END IF;

  -- Only application-owned functions are checked. Internal functions installed
  -- by extensions such as pg_trgm are not application RPC endpoints.
  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    LEFT JOIN pg_depend d
      ON d.classid = 'pg_proc'::regclass
     AND d.objid = p.oid
     AND d.deptype = 'e'
    LEFT JOIN pg_extension e ON e.oid = d.refobjid
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND e.oid IS NULL
      AND has_function_privilege('anon', p.oid, 'EXECUTE')
  ) THEN
    failures := array_append(failures, 'anon conserva EXECUTE sobre RPC propias');
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND p.prosecdef
      AND coalesce(array_to_string(p.proconfig, ','), '') NOT LIKE '%search_path=public, pg_temp%'
  ) THEN
    failures := array_append(failures, 'Hay funciones SECURITY DEFINER sin search_path fijo');
  END IF;

  IF (
    SELECT count(*)
    FROM pg_policies
    WHERE schemaname = 'public'
      AND policyname = 'authenticated_crm_access'
  ) <> (
    SELECT count(*)
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
  ) THEN
    failures := array_append(failures, 'No todas las tablas tienen la política authenticated_crm_access');
  END IF;

  IF coalesce(array_length(failures, 1), 0) > 0 THEN
    RAISE EXCEPTION 'DEV auth boundary FAILED: %', array_to_string(failures, '; ');
  END IF;
END
$$;

SELECT jsonb_build_object(
  'status', 'PASS',
  'tables_rls', (
    SELECT count(*)
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
      AND c.relrowsecurity
  ),
  'anon_tables_with_dml', (
    SELECT count(*)
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
      AND has_table_privilege('anon', c.oid, 'SELECT,INSERT,UPDATE,DELETE')
  ),
  'anon_executable_app_functions', (
    SELECT count(*)
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    LEFT JOIN pg_depend d
      ON d.classid = 'pg_proc'::regclass
     AND d.objid = p.oid
     AND d.deptype = 'e'
    LEFT JOIN pg_extension e ON e.oid = d.refobjid
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND e.oid IS NULL
      AND has_function_privilege('anon', p.oid, 'EXECUTE')
  )
) AS result;

-- Runtime negative test (must fail with permission denied):
-- BEGIN;
-- SET LOCAL ROLE anon;
-- SELECT count(*) FROM public.contacts;
-- ROLLBACK;

-- Runtime authenticated test (must return the DEV contact count):
-- BEGIN;
-- SELECT set_config(
--   'request.jwt.claims',
--   jsonb_build_object(
--     'sub', (SELECT id::text FROM auth.users ORDER BY created_at LIMIT 1),
--     'role', 'authenticated'
--   )::text,
--   true
-- );
-- SET LOCAL ROLE authenticated;
-- SELECT count(*) FROM public.contacts;
-- ROLLBACK;
