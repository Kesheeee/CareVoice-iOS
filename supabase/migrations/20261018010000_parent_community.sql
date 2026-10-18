-- CareVoice community: only deliberate posts/replies leave the device.
-- Never add child profiles, observation records, or AI conversations to these tables.
begin;
create schema if not exists carevoice_private;
revoke all on schema carevoice_private from public, anon, authenticated;
grant usage on schema carevoice_private to authenticated;

create table public.community_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) <= 40 and char_length(btrim(display_name)) >= 2),
  created_at timestamptz not null default now()
);
create table carevoice_private.community_moderators (
  user_id uuid primary key references auth.users(id) on delete cascade
);
create table public.community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.community_profiles(user_id) on delete cascade default auth.uid(),
  topic text not null check (topic in ('everyday','assessment','school','waiting','celebrations')),
  title text not null check (char_length(title) <= 120 and char_length(btrim(title)) >= 3),
  body text not null check (char_length(body) <= 3000 and char_length(btrim(body)) >= 1),
  status text not null default 'visible' check (status in ('visible','removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.community_replies (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  author_id uuid not null references public.community_profiles(user_id) on delete cascade default auth.uid(),
  body text not null check (char_length(body) <= 1500 and char_length(btrim(body)) >= 1),
  status text not null default 'visible' check (status in ('visible','removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.community_blocks (
  blocker_id uuid not null references public.community_profiles(user_id) on delete cascade default auth.uid(),
  blocked_id uuid not null references public.community_profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(blocker_id, blocked_id), check(blocker_id <> blocked_id)
);
create table public.community_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  target_kind text not null check(target_kind in ('post','reply')),
  target_id uuid not null,
  reason text not null check (reason in ('privacy','harmful','harassment','spam','other')),
  detail text not null default '' check(char_length(detail) <= 1000),
  state text not null default 'open' check(state in ('open','dismissed','removed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  unique(reporter_id, target_kind, target_id)
);
create table carevoice_private.community_moderation_log (
  id bigint generated always as identity primary key,
  moderator_id uuid references auth.users(id) on delete set null,
  report_id uuid references public.community_reports(id) on delete set null,
  action text not null,
  created_at timestamptz not null default now()
);
create index community_posts_feed on public.community_posts (created_at desc, id desc);
create index community_posts_author on public.community_posts (author_id, created_at desc);
create index community_posts_topic on public.community_posts (topic, created_at desc);
create index community_replies_thread on public.community_replies (post_id, created_at, id);
create index community_replies_author on public.community_replies (author_id, created_at desc);
create index community_blocks_reverse on public.community_blocks (blocked_id, blocker_id);
create index community_reports_queue on public.community_reports (state, created_at);
create index community_reports_reporter on public.community_reports (reporter_id, created_at);
create index community_moderation_actor on carevoice_private.community_moderation_log (moderator_id);
create index community_moderation_report on carevoice_private.community_moderation_log (report_id);

alter table public.community_profiles enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_replies enable row level security;
alter table public.community_blocks enable row level security;
alter table public.community_reports enable row level security;
alter table carevoice_private.community_moderators enable row level security;
alter table carevoice_private.community_moderation_log enable row level security;
revoke all on public.community_profiles, public.community_posts, public.community_replies,
  public.community_blocks, public.community_reports from anon, authenticated;
revoke all on all tables in schema carevoice_private from public, anon, authenticated;

-- These narrow private helpers deliberately read protected identity/role/block tables.
-- Their answers are always scoped to auth.uid(), never a caller-selected viewer.
create function carevoice_private.community_member() returns boolean language sql stable security definer
set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from auth.users where id = auth.uid() and email_confirmed_at is not null
      and coalesce(is_anonymous, false) = false and (banned_until is null or banned_until < now())
  );
$$;
create function carevoice_private.community_moderator() returns boolean language sql stable security definer
set search_path = '' as $$
  select carevoice_private.community_member() and exists (
    select 1 from carevoice_private.community_moderators where user_id = auth.uid()
  );
$$;
create function carevoice_private.community_blocked(other_user uuid) returns boolean language sql stable security definer
set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.community_blocks where
      (blocker_id = auth.uid() and blocked_id = other_user) or
      (blocked_id = auth.uid() and blocker_id = other_user)
  );
$$;
revoke execute on all functions in schema carevoice_private from public, anon, authenticated;
grant execute on function carevoice_private.community_member(), carevoice_private.community_moderator(),
  carevoice_private.community_blocked(uuid) to authenticated;

grant select on public.community_profiles, public.community_posts, public.community_replies,
  public.community_blocks, public.community_reports to authenticated;
grant insert(user_id, display_name), update(display_name) on public.community_profiles to authenticated;
grant insert(topic, title, body), update(topic, title, body), delete on public.community_posts to authenticated;
grant insert(post_id, body), update(body), delete on public.community_replies to authenticated;
grant insert(blocked_id), delete on public.community_blocks to authenticated;
grant insert(target_kind, target_id, reason, detail) on public.community_reports to authenticated;

create policy profiles_read on public.community_profiles for select to authenticated
using ((select carevoice_private.community_member()));
create policy profiles_create on public.community_profiles for insert to authenticated
with check ((select carevoice_private.community_member()) and user_id = (select auth.uid()));
create policy profiles_edit on public.community_profiles for update to authenticated
using ((select carevoice_private.community_member()) and user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy posts_read on public.community_posts for select to authenticated using (
 (select carevoice_private.community_member()) and (author_id = (select auth.uid())
 or (select carevoice_private.community_moderator())
 or (status = 'visible' and not carevoice_private.community_blocked(author_id)))
);
create policy posts_create on public.community_posts for insert to authenticated with check (
 (select carevoice_private.community_member()) and author_id = (select auth.uid()) and status = 'visible'
);
create policy posts_edit on public.community_posts for update to authenticated
using ((select carevoice_private.community_member()) and author_id = (select auth.uid()))
with check (author_id = (select auth.uid()));
create policy posts_delete on public.community_posts for delete to authenticated
using ((select carevoice_private.community_member()) and author_id = (select auth.uid()));

create policy replies_read on public.community_replies for select to authenticated using (
 (select carevoice_private.community_member()) and
 ((select carevoice_private.community_moderator()) or
 (exists(select 1 from public.community_posts p where p.id = post_id and p.status = 'visible')
 and (author_id = (select auth.uid()) or (status = 'visible' and not carevoice_private.community_blocked(author_id)))))
);
create policy replies_create on public.community_replies for insert to authenticated with check (
 (select carevoice_private.community_member()) and author_id = (select auth.uid()) and status = 'visible'
 and exists(select 1 from public.community_posts p where p.id = post_id and p.status = 'visible'
   and not carevoice_private.community_blocked(p.author_id))
);
create policy replies_edit on public.community_replies for update to authenticated
using ((select carevoice_private.community_member()) and author_id = (select auth.uid()))
with check (author_id = (select auth.uid()));
create policy replies_delete on public.community_replies for delete to authenticated
using ((select carevoice_private.community_member()) and author_id = (select auth.uid()));
create policy blocks_read on public.community_blocks for select to authenticated
using ((select carevoice_private.community_member()) and blocker_id = (select auth.uid()));
create policy blocks_create on public.community_blocks for insert to authenticated
with check ((select carevoice_private.community_member()) and blocker_id = (select auth.uid()));
create policy blocks_delete on public.community_blocks for delete to authenticated
using ((select carevoice_private.community_member()) and blocker_id = (select auth.uid()));
create policy reports_read on public.community_reports for select to authenticated
using ((select carevoice_private.community_member()) and
 (reporter_id = (select auth.uid()) or (select carevoice_private.community_moderator())));
create policy reports_create on public.community_reports for insert to authenticated with check (
 (select carevoice_private.community_member()) and reporter_id = (select auth.uid()) and state = 'open'
 and ((target_kind = 'post' and exists(select 1 from public.community_posts p where p.id = target_id and p.status = 'visible'))
 or (target_kind = 'reply' and exists(select 1 from public.community_replies r where r.id = target_id and r.status = 'visible')))
);

create function carevoice_private.community_edit_time() returns trigger language plpgsql
set search_path = '' as $$ begin new.updated_at = now(); return new; end; $$;
create trigger post_edit_time before update on public.community_posts for each row execute function carevoice_private.community_edit_time();
create trigger reply_edit_time before update on public.community_replies for each row execute function carevoice_private.community_edit_time();

-- Server-side limits apply even when the client UI is bypassed.
create function carevoice_private.community_rate_limit() returns trigger language plpgsql security definer
set search_path = '' as $$
declare total integer;
begin
 if auth.uid() is null then return new; end if;
 if not carevoice_private.community_member() then raise exception 'community_sign_in_required' using errcode = '42501'; end if;
 perform pg_advisory_xact_lock(hashtext(auth.uid()::text));
 if tg_table_name = 'community_posts' then
   select count(*) into total from public.community_posts where author_id = auth.uid() and created_at > now() - interval '5 minutes';
   if total >= 5 then raise exception 'community_rate_limit'; end if;
 elsif tg_table_name = 'community_replies' then
   select count(*) into total from public.community_replies where author_id = auth.uid() and created_at > now() - interval '5 minutes';
   if total >= 20 then raise exception 'community_rate_limit'; end if;
 else
   select count(*) into total from public.community_reports where reporter_id = auth.uid() and created_at > now() - interval '1 day';
   if total >= 10 then raise exception 'community_rate_limit'; end if;
 end if;
 return new;
end; $$;
create trigger post_rate_limit before insert on public.community_posts for each row execute function carevoice_private.community_rate_limit();
create trigger reply_rate_limit before insert on public.community_replies for each row execute function carevoice_private.community_rate_limit();
create trigger report_rate_limit before insert on public.community_reports for each row execute function carevoice_private.community_rate_limit();

-- Security-invoker APIs retain all table policies, including block and removal filtering.
create function public.community_feed(p_before timestamptz default null, p_before_id uuid default null,
 p_topic text default null, p_mine boolean default false, p_post_id uuid default null)
returns table(id uuid, author_id uuid, author_name text, topic text, title text, body text, status text,
 created_at timestamptz, updated_at timestamptz, reply_count bigint)
language sql stable security invoker set search_path = '' as $$
 select p.id, p.author_id, u.display_name, p.topic, p.title, p.body, p.status, p.created_at, p.updated_at,
 (select count(*) from public.community_replies r where r.post_id = p.id and r.status = 'visible')
 from public.community_posts p join public.community_profiles u on u.user_id = p.author_id
 where (p_mine is false or p.author_id = auth.uid()) and (p_topic is null or p.topic = p_topic)
 and (p_post_id is null or p.id = p_post_id)
 and (p_mine or p_post_id is not null or p.status = 'visible')
 and (p_before is null or (p.created_at,p.id) < (p_before,p_before_id))
 order by p.created_at desc, p.id desc limit 20;
$$;
create function public.community_thread(p_post_id uuid, p_after timestamptz default null, p_after_id uuid default null)
returns table(id uuid, post_id uuid, author_id uuid, author_name text, body text, status text, created_at timestamptz, updated_at timestamptz)
language sql stable security invoker set search_path = '' as $$
 select r.id,r.post_id,r.author_id,u.display_name,r.body,r.status,r.created_at,r.updated_at
 from public.community_replies r join public.community_profiles u on u.user_id = r.author_id
 where r.post_id = p_post_id and (p_after is null or (r.created_at,r.id) > (p_after,p_after_id))
 order by r.created_at, r.id limit 30;
$$;
create function public.community_is_moderator() returns boolean language sql stable security invoker
set search_path = '' as $$ select carevoice_private.community_moderator(); $$;

create function carevoice_private.resolve_community_report(p_report_id uuid, p_action text)
returns boolean language plpgsql security definer set search_path = '' as $$
declare report public.community_reports;
begin
 if auth.uid() is null or not carevoice_private.community_moderator() then raise exception 'moderator_required' using errcode = '42501'; end if;
 if p_action not in ('dismissed','removed') then raise exception 'invalid_action'; end if;
 select * into report from public.community_reports where id = p_report_id and state = 'open' for update;
 if not found then raise exception 'report_already_resolved'; end if;
 if p_action = 'removed' then
   if report.target_kind = 'post' then update public.community_posts set status = 'removed' where id = report.target_id;
   else update public.community_replies set status = 'removed' where id = report.target_id; end if;
 end if;
 update public.community_reports set state = p_action, resolved_at = now() where id = p_report_id;
 insert into carevoice_private.community_moderation_log(moderator_id,report_id,action) values(auth.uid(),p_report_id,p_action);
 return true;
end; $$;
create function public.community_resolve_report(p_report_id uuid, p_action text) returns boolean
language sql security invoker set search_path = '' as $$ select carevoice_private.resolve_community_report(p_report_id,p_action); $$;

create function carevoice_private.delete_community_account() returns boolean language plpgsql security definer
set search_path = '' as $$
begin
 if auth.uid() is null or not carevoice_private.community_member() then raise exception 'community_sign_in_required' using errcode = '42501'; end if;
 -- Membership policies also check auth.users, so an outstanding JWT loses access immediately.
 delete from auth.users where id = auth.uid();
 return true;
end; $$;
create function public.community_delete_account() returns boolean language sql security invoker
set search_path = '' as $$ select carevoice_private.delete_community_account(); $$;

revoke execute on all functions in schema carevoice_private from public, anon;
revoke execute on function public.community_feed(timestamptz,uuid,text,boolean,uuid),
 public.community_thread(uuid,timestamptz,uuid), public.community_is_moderator(),
 public.community_resolve_report(uuid,text), public.community_delete_account() from public, anon;
grant execute on function carevoice_private.resolve_community_report(uuid,text),carevoice_private.delete_community_account() to authenticated;
grant execute on function public.community_feed(timestamptz,uuid,text,boolean,uuid),
 public.community_thread(uuid,timestamptz,uuid), public.community_is_moderator(),
 public.community_resolve_report(uuid,text), public.community_delete_account() to authenticated;
commit;
