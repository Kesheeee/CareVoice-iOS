-- ONLY for an empty disposable PostgreSQL CI database, never a Supabase project.
create role anon nologin;
create role authenticated nologin;
create schema auth;
create table auth.users (
 id uuid primary key, email_confirmed_at timestamptz, is_anonymous boolean default false, banned_until timestamptz
);
create function auth.uid() returns uuid language sql stable as $$
 select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
grant usage on schema auth to authenticated, anon;
grant execute on function auth.uid() to authenticated, anon;
