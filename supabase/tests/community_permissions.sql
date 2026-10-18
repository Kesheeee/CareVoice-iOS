\set ON_ERROR_STOP on
begin;
create schema community_test;
grant usage on schema community_test to anon, authenticated;
create function community_test.assert_true(result boolean, label text) returns void language plpgsql as $$
begin if result is distinct from true then raise exception 'FAILED: %',label; end if; end; $$;
create function community_test.denied(statement text) returns void language plpgsql as $$
begin
 begin execute statement;
 exception when insufficient_privilege then return; end;
 raise exception 'Expected permission denial: %',statement;
end; $$;

insert into auth.users(id,email_confirmed_at) values
 ('11111111-1111-1111-1111-111111111111',now()),
 ('22222222-2222-2222-2222-222222222222',now()),
 ('33333333-3333-3333-3333-333333333333',now()),
 ('44444444-4444-4444-4444-444444444444',null);
insert into carevoice_private.community_moderators values('33333333-3333-3333-3333-333333333333');

set local role anon;
select community_test.denied('select * from public.community_posts');
select community_test.denied('select public.community_is_moderator()');
reset role;

set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local role authenticated;
insert into public.community_profiles(user_id,display_name) values(auth.uid(),'Parent A');
insert into public.community_posts(topic,title,body) values('everyday','A question','A synthetic test discussion') returning id as alice_post \gset
select community_test.assert_true((select count(*)=1 from public.community_feed()), 'owner can read feed');
select community_test.denied('insert into carevoice_private.community_moderators values (auth.uid())');
select community_test.denied('update public.community_posts set status = ''visible''');
select community_test.denied('insert into public.community_posts(author_id,topic,title,body) values(''22222222-2222-2222-2222-222222222222'',''everyday'',''Spoofed'',''No'')');
update public.community_posts set title='Edited by parent A' where id=:'alice_post';
select community_test.assert_true((select title='Edited by parent A' from public.community_posts where id=:'alice_post'), 'owner can edit');
reset role;

set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
set local role authenticated;
insert into public.community_profiles(user_id,display_name) values(auth.uid(),'Parent B');
select community_test.assert_true((select count(*)=1 from public.community_feed()), 'other member can read');
with changed as (update public.community_posts set title='Unauthorized' where id=:'alice_post' returning id)
select community_test.assert_true((select count(*)=0 from changed), 'cannot edit another author');
with deleted as (delete from public.community_posts where id=:'alice_post' returning id)
select community_test.assert_true((select count(*)=0 from deleted), 'cannot delete another author');
insert into public.community_replies(post_id,body) values(:'alice_post','A synthetic reply') returning id as bob_reply \gset
update public.community_replies set body='Edited reply' where id=:'bob_reply';
select community_test.assert_true((select reply_count=1 from public.community_feed()), 'reply count follows visible replies');
insert into public.community_reports(target_kind,target_id,reason,detail)
 values('post',:'alice_post','privacy','Synthetic report') returning id as report_id \gset
select community_test.assert_true((select count(*)=1 from public.community_reports),'reporter sees own report');
select community_test.denied(format('select public.community_resolve_report(%L,''removed'')', :'report_id'));
reset role;

set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local role authenticated;
select community_test.assert_true((select count(*)=0 from public.community_reports),'author cannot read someone else report');
insert into public.community_blocks(blocked_id) values('22222222-2222-2222-2222-222222222222');
select community_test.assert_true((select count(*)=0 from public.community_thread(:'alice_post')),'block hides replies');
select community_test.assert_true((select reply_count=0 from public.community_feed()),'block hides reply count');
reset role;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
set local role authenticated;
select community_test.assert_true((select count(*)=0 from public.community_feed()),'blocked member cannot see blockers posts');
select community_test.denied(format('insert into public.community_replies(post_id,body) values(%L,''Blocked reply'')', :'alice_post'));
select community_test.assert_true((select count(*)=0 from public.community_blocks),'block list is private');
reset role;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local role authenticated;
delete from public.community_blocks where blocked_id='22222222-2222-2222-2222-222222222222';
select community_test.assert_true((select count(*)=1 from public.community_thread(:'alice_post')),'unblock restores replies');
reset role;

set local request.jwt.claim.sub = '44444444-4444-4444-4444-444444444444';
set local role authenticated;
select community_test.assert_true((select count(*)=0 from public.community_feed()),'unverified account cannot read');
select community_test.denied('insert into public.community_profiles(user_id,display_name) values(auth.uid(),''Unverified'')');
reset role;

set local request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';
set local role authenticated;
select community_test.assert_true(public.community_is_moderator(),'moderator role from private table');
select community_test.assert_true((select count(*)=1 from public.community_reports),'moderator sees reports');
select community_test.assert_true(public.community_resolve_report(:'report_id','removed'),'moderator removes content');
reset role;
select community_test.assert_true((select count(*)=1 from carevoice_private.community_moderation_log),'moderation audit logged');
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
set local role authenticated;
select community_test.assert_true((select count(*)=0 from public.community_feed()),'removed post absent from feed');
select community_test.assert_true((select count(*)=0 from public.community_thread(:'alice_post')),'removed thread replies hidden');
select community_test.assert_true(public.community_delete_account(),'user can delete own account');
select community_test.assert_true((select count(*)=0 from public.community_profiles),'old JWT loses access after deletion');
select community_test.denied('insert into public.community_profiles(user_id,display_name) values(auth.uid(),''Deleted user'')');
reset role;
select community_test.assert_true((select count(*)=0 from public.community_replies),'account deletion removes authored replies');

set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local role authenticated;
select community_test.assert_true((select count(*)=1 from public.community_feed(p_mine=>true)),'owner sees removed post in My posts');
select community_test.denied('update public.community_posts set status=''visible''');
delete from public.community_posts where id=:'alice_post';
select community_test.assert_true((select count(*)=0 from public.community_feed(p_mine=>true)),'owner can delete removed post');
reset role;
rollback;
\echo 'Community permission checks passed.'
