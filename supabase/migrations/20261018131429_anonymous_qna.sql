begin;
create table public.qna_entries (
 id uuid primary key default gen_random_uuid(),
 author_id uuid not null references auth.users(id) on delete cascade,
 question_id uuid references public.qna_entries(id) on delete cascade,
 body text not null check(char_length(btrim(body)) between 3 and 2000),
 hidden boolean not null default false,
 created_at timestamptz not null default now()
);
create index qna_feed on public.qna_entries(question_id, created_at desc);
create index qna_author on public.qna_entries(author_id, created_at desc);
create table public.qna_reports (
 id uuid primary key default gen_random_uuid(),
 entry_id uuid not null references public.qna_entries(id) on delete cascade,
 reporter_id uuid not null references auth.users(id) on delete cascade,
 reason text not null check(reason in ('privacy','harmful','spam','other')),
 created_at timestamptz not null default now(),
 unique(entry_id,reporter_id)
);
create index qna_reports_reporter on public.qna_reports(reporter_id);
alter table public.qna_entries enable row level security;
alter table public.qna_reports enable row level security;
-- Only the authenticated Edge Function can read identity-bearing rows.
revoke all on public.qna_entries,public.qna_reports from public,anon,authenticated;
grant select,insert,update,delete on public.qna_entries,public.qna_reports to service_role;
create function carevoice_private.qna_validate_insert() returns trigger
language plpgsql security invoker set search_path='' as $$
begin
 perform pg_advisory_xact_lock(hashtextextended(new.author_id::text,0));
 if (select count(*) from public.qna_entries where author_id=new.author_id and created_at>now()-interval '1 minute') >= 5 then
  raise exception 'qna_rate_limit';
 end if;
 if new.question_id is not null and not exists(select 1 from public.qna_entries where id=new.question_id and question_id is null and not hidden) then
  raise exception 'qna_question_unavailable';
 end if;
 return new;
end;
$$;
revoke all on function carevoice_private.qna_validate_insert() from public,anon,authenticated;
create trigger qna_validate before insert on public.qna_entries for each row execute function carevoice_private.qna_validate_insert();
commit;
