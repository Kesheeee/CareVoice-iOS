# Parent community setup

The native app and `review/CareVoiceComplete.swift` contain the same text-only parent community implementation. The web prototype is unchanged.

Implemented: verified email-code sign-in, a separate public nickname, topic-filtered feed with cursor pagination, My posts, post/reply create/edit/delete, private reports, two-way blocks and unblock, moderator review/removal/dismissal, audit records, sign-out, and community account deletion. Personal child profiles, questionnaires and observations are never uploaded by this feature. Session tokens use the device-only iOS Keychain; no service-role secret belongs in the app.

## Connect the project

### Current review environment — 18 October 2026

- Dedicated **CareVoice** project in **Kesheeee's Org**, Singapore (`ap-southeast-1`): `lbbpuwtwhiectsmhhuej`.
- Project URL: `https://lbbpuwtwhiectsmhhuej.supabase.co`. Both native source and the full Swift review file use its public publishable key. No privileged keys are included.
- The `parent_community` migration is applied. The permission scenarios were also run against the live Supabase auth schema inside a rolled-back transaction; no test users or discussions remain. Anonymous REST access returns 401 / permission denied.
- Email authentication and email confirmation are enabled; anonymous authentication is disabled.
- **Still pending:** set the Magic Link template to include `{{ .Token }}` in the [dashboard](https://supabase.com/dashboard/project/lbbpuwtwhiectsmhhuej/auth/templates), verify email delivery with consenting testers, configure production SMTP, and assign a verified moderator. Dashboard sign-in is required to finish the template change. The email-code flow has not yet been tested end to end.
- Security advisors reported only two informational notices for private moderator/audit tables having RLS with no policies. This is intentional deny-by-default behavior: those tables are accessed through restricted helpers, not directly by app users. See [RLS without policies](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

1. Create/select a dedicated CareVoice Supabase project. Do not use another app's database without explicit approval.
2. Apply `supabase/migrations/20261018010000_parent_community.sql` with the Supabase migration workflow. It creates new community tables, restricted grants, RLS and narrow private authorization helpers. Do not run `bootstrap_ci.sql` on Supabase; that file is only an auth-schema stub for disposable CI databases.
3. Enable email authentication with email confirmation. For **Magic Link** in Authentication → Email Templates, include `{{ .Token }}` so the app's email-code field can verify the message. Example:

   ```html
   <h2>Your CareVoice sign-in code</h2>
   <p>Enter this code in CareVoice: {{ .Token }}</p>
   ```

   Configure production SMTP before inviting parents. Supabase's default sender is restricted and intended for development; do not disable verification as a workaround. Review Auth rate limits and enable CAPTCHA protection before broad public distribution (the current client does not include a CAPTCHA challenge UI).
4. Set the HTTPS project URL and **publishable** (`sb_publishable_…`) key in `CommunityConfiguration`, in both `CareVoice/CommunityStore.swift` and the full review file. Alternatively add `CareVoiceCommunityURL` and `CareVoiceCommunityPublishableKey` to the target's Info.plist. These values are public client configuration. Secret/service-role keys are rejected by the client configuration.
5. Select a moderator after that person signs in. An administrator can run:

   ```sql
   insert into carevoice_private.community_moderators(user_id)
   values ('<verified-user-uuid>');
   ```

   Users cannot promote themselves; JWT user metadata is not used for authorization. The moderation queue appears on the Community account page after the next sign-in or app launch.

## Verify before a pilot

- Use two consenting test accounts and one moderator. Verify email-code delivery, Keychain restoration, expired-session refresh, feed pagination, create/edit/delete, reply pagination, report, block/unblock, and moderator actions on devices.
- Confirm only an owner's own content can be edited/deleted, and removed content cannot be republished by editing its status. The committed database test runs these boundaries against PostgreSQL in GitHub Actions.
- Review Supabase security advisors after applying the migration. Public tables all have RLS; public APIs execute with caller privileges. Private security-definer helpers have a fixed empty search path, explicit auth checks, and revoked PUBLIC execution.
- Server limits are five currently retained posts per five minutes, twenty retained replies per five minutes, and ten retained reports per day per account. These are basic abuse controls, not a substitute for operational moderation or service-wide quotas.
- The UI shows a connection-pending state until configuration exists. There are no seeded parents, fake posts, or simulated successful publishing. UI tests explicitly disable the live connection.
- Establish a staffed moderation process, support contact, final community guidelines, privacy policy and terms before public launch. The current policy pages describe a review build and do not collect legal acceptance.

## Data and deletion

Only verified, non-anonymous, non-banned accounts may read or participate. Posts are visible to signed-in members, subject to removal and two-way blocks. Public nickname records contain no email or child details. Reports are readable only by their reporter and moderators. Block lists are private to the blocker.

Deleting a community account removes its auth identity, public profile, posts, replies, blocks and submitted reports through cascading constraints. Moderator audit entries retain the action with the deleted user identifier set to null. Membership policies check the auth user row, so a previously issued JWT loses access after deletion. This action does not erase the device's child records. The separate Settings → Data & privacy deletion affects local records only.

This implementation does not include media uploads, direct messages, push notifications, AI matching, or caregiver-story reuse for AI. Those are separate future features.

References: [Supabase email OTP](https://supabase.com/docs/guides/auth/auth-email-passwordless), [Row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security).
