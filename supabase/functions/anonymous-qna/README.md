# Anonymous community Q&A

The Community screen calls the authenticated `anonymous-qna` Edge Function. Only signed-in, non-anonymous Supabase accounts may read or publish. Anonymity is relative to other community members, not CareVoice administrators.

The browser never reads the backing tables. RLS is enabled with no client policies, and all `anon`/`authenticated` grants are revoked. The server validates the user token, binds writes to that user, and returns only `id`, `body`, `createdAt`, and `isMine`. No display name, email, account ID, child profile, tracker record, or chat is returned or copied into posts.

Actions: feed, thread, post, reply, remove, report. Feeds paginate 50 at a time; Refresh fetches new posts. Publishing requires explicit confirmation that identifying details were removed. Posts remain plain text. Removal hides the owner's content; a removed question's replies cannot be fetched. A database trigger limits each account to five entries per minute. Reports are idempotent per member and entry.

Moderation: trusted project admins review `public.qna_reports` in Supabase and set `public.qna_entries.hidden = true` for content that should be removed. Reporting does not automatically hide content or send a notification. There is no automatic content moderation or AI answer generation.

Deployment: apply the generated `anonymous_qna` migration, then deploy `anonymous-qna` with JWT verification enabled. Built-in Supabase URL, anon key and service role environment variables are used; the service role stays server-side.

Validation performed: a live two-account test of shared questions/replies, ownership enforcement, anonymous response fields, direct-table access denial, reporting and removal; browser test of explicit publication and reply flow at mobile width. Temporary users and their rows were deleted after testing.

Security advisor: no-policy INFO notices on these two tables are intentional deny-by-default protection. The project also has a pre-existing [leaked-password protection warning](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection); this change does not alter Auth settings.
