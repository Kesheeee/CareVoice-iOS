# Parent community setup

The native app and `review/CareVoiceComplete.swift` contain the same text-only parent community implementation. The web prototype is unchanged.

Implemented: shared CareVoice email/password sign-in, a separate public nickname and community-guidelines agreement, topic-filtered feed with cursor pagination, My posts, post/reply create/edit/delete, private reports, two-way blocks and unblock, moderator review/removal/dismissal, audit records, sign-out, and account deletion. Parent conversations reuse the existing app session; there is no separate email-code login. Personal child profiles, questionnaires and observations are never uploaded by this feature. Session tokens use the device-only iOS Keychain; no service-role secret belongs in the app.

## Connect the project

### Current review environment — 18 October 2026

- Dedicated **CareVoice** project in **Kesheeee's Org**, Singapore (`ap-southeast-1`): `lbbpuwtwhiectsmhhuej`.
- Project URL: `https://lbbpuwtwhiectsmhhuej.supabase.co`. Both native source and the full Swift review file use its public publishable key. No privileged keys are included.
- The `parent_community` migration is applied. The permission scenarios were also run against the live Supabase auth schema inside a rolled-back transaction; no test users or discussions remain. Anonymous REST access returns 401 / permission denied.
- Email/password authentication and new signups are enabled. **Confirm email is OFF for testing**, explicitly approved by the owner on 18 October 2026 and verified after saving. Anonymous authentication remains disabled. Password requirements remain at least eight characters with uppercase, lowercase, a number and a symbol; other rate limits remain in place.
- Both native and TypeScript signup already accept an immediately issued server session. The testing configuration avoids sending a signup confirmation email; it does not verify ownership of the supplied email address. A user-only response does not grant app access. Both clients keep their confirmation fallback if the setting is enabled again. Changing this shared backend setting does not require a Vercel or iPhone rebuild.
- **Still pending for a public pilot:** configure production SMTP, re-enable email confirmation, verify delivery and password recovery with consenting testers, and assign a verified moderator. Password recovery still sends email and is subject to sender limits. No Magic Link code-template change is needed for the current password login.
- Security advisors reported only two informational notices for private moderator/audit tables having RLS with no policies. This is intentional deny-by-default behavior: those tables are accessed through restricted helpers, not directly by app users. See [RLS without policies](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

1. Create/select a dedicated CareVoice Supabase project. Do not use another app's database without explicit approval.
2. Apply `supabase/migrations/20261018010000_parent_community.sql` with the Supabase migration workflow. It creates new community tables, restricted grants, RLS and narrow private authorization helpers. Do not run `bootstrap_ci.sql` on Supabase; that file is only an auth-schema stub for disposable CI databases.
3. Enable email/password authentication. For the current owner-approved testing environment, leave **Confirm email OFF** in Authentication → Sign In / Providers. For a public pilot, configure production SMTP and turn confirmation back on; verify the confirmation and recovery redirects return to the deployed CareVoice HTTPS page. Supabase's default sender is restricted and intended for development. Review Auth rate limits and enable CAPTCHA protection before broad public distribution (the current client does not include a CAPTCHA challenge UI).
4. Set the HTTPS project URL and **publishable** (`sb_publishable_…`) key in `CommunityConfiguration`, in both `CareVoice/CommunityStore.swift` and the full review file. Alternatively add `CareVoiceCommunityURL` and `CareVoiceCommunityPublishableKey` to the target's Info.plist. These values are public client configuration. Secret/service-role keys are rejected by the client configuration.
5. Select a moderator after that person signs in. An administrator can run:

   ```sql
   insert into carevoice_private.community_moderators(user_id)
   values ('<verified-user-uuid>');
   ```

   Users cannot promote themselves; JWT user metadata is not used for authorization. The moderation queue appears on the Community account page after the next sign-in or app launch.

## Verify before a pilot

- Use two consenting test accounts and one moderator. Verify email/password signup and sign-in, Keychain restoration, expired-session refresh, feed pagination, create/edit/delete, reply pagination, report, block/unblock, and moderator actions on devices. Before a public pilot, also verify confirmation and recovery email delivery after configuring SMTP and re-enabling confirmation. Simulator fixtures do not prove live signup or email delivery.
- Confirm only an owner's own content can be edited/deleted, and removed content cannot be republished by editing its status. The committed database test runs these boundaries against PostgreSQL in GitHub Actions.
- Review Supabase security advisors after applying the migration. Public tables all have RLS; public APIs execute with caller privileges. Private security-definer helpers have a fixed empty search path, explicit auth checks, and revoked PUBLIC execution.
- Server limits are five currently retained posts per five minutes, twenty retained replies per five minutes, and ten retained reports per day per account. These are basic abuse controls, not a substitute for operational moderation or service-wide quotas.
- The UI shows a connection-pending state until configuration exists. There are no seeded parents, fake posts, or simulated successful publishing. UI tests explicitly disable the live connection.
- Establish a staffed moderation process, support contact, final community guidelines, privacy policy and terms before public launch. The current policy pages describe a review build and do not collect legal acceptance.

## Data and deletion

Only authenticated, non-anonymous, non-banned accounts with a server-confirmed email timestamp may read or participate. With Confirm email OFF, Supabase automatically confirms new signups; that timestamp does not prove email ownership in testing mode. RLS and session checks remain in place. Posts are visible to signed-in members, subject to removal and two-way blocks. Public nickname records contain no email or child details. Reports are readable only by their reporter and moderators. Block lists are private to the blocker.

Deleting a community account removes its auth identity, public profile, posts, replies, blocks and submitted reports through cascading constraints. Moderator audit entries retain the action with the deleted user identifier set to null. Membership policies check the auth user row, so a previously issued JWT loses access after deletion. This action does not erase the device's child records. The separate Settings → Data & privacy deletion affects local records only.

This implementation does not include media uploads, direct messages, push notifications, AI matching, or caregiver-story reuse for AI. Those are separate future features.

References: [Supabase password authentication](https://supabase.com/docs/guides/auth/passwords), [Auth configuration](https://supabase.com/docs/guides/auth/general-configuration), [Email delivery](https://supabase.com/docs/guides/auth/auth-smtp), [Row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security).
