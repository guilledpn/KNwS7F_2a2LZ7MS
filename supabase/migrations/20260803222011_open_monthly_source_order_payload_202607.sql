create table public._mso_payload_202607 (
  seq integer primary key,
  part text not null,
  created_at timestamptz not null default now()
);
alter table public._mso_payload_202607 enable row level security;
revoke all on table public._mso_payload_202607 from anon, authenticated;
comment on table public._mso_payload_202607 is 'Temporary encrypted transport for canonical July 2026 source order; remove immediately after verified load.';
