# Product decisions and handoff

## Reconciled source conflicts

- Removed numeric dimension/total scores and “stage judgment” from the results mockup. Queenie's onboarding document forbids diagnosis/severity inference and scores. The result is a response review.
- Six journey stages follow the onboarding document; the caregiver selects them. Questionnaire answers do not alter stage.
- Promoted “Not sure” to every question, retained skip, and made regression answers trigger immediate guidance independent of questionnaire completion.
- Show the questionnaire prominently to caregivers just noticing differences; other stages can open it voluntarily from Profile.
- Collect age in months and optional nickname, not a real name, photo or precise birth date.
- Use native iOS navigation, flexible cards, semantic backgrounds and Dynamic Type instead of reproducing the decorative phone frame.
- Label the community section Resources: this version supplies official links, not a discussion forum.
- Removed unsupported referral-expiry, subsidy-eligibility and emergency-routing claims from prototype copy. The navigator does not register a child or assert a waiting time.

## Current implementation limits

- One child profile per installation, no login or device-to-device/family sharing.
- No AI classification, clinical interpretation, automatic trigger detection or conversational follow-up. A caregiver enters/edits the observation and category. Related entries use explicit categories.
- Voice is Apple on-device transcription for en-US and zh-HK where supported. It requires speech/microphone permission and local recognizer availability. Physical-device Cantonese and English recordings still need validation.
- Reports export all saved observations; date-range filtering and clinician templates are future extensions.
- Questionnaire prompts are supplied team content, not a validated screening instrument. Age tailoring and content approval require the team's review before public deployment.
- Official service links are verified; no live availability, subsidy calculation or booking integration.
- Signing/team configuration, TestFlight, App Store submission and production accessibility/privacy review are separate release tasks.

## Suggested collaboration split

One developer can work on the questionnaire/profile flow and content review while the other works on records, report formatting and speech. Keep model changes small and coordinate any persistence schema change before merging.

## Future work

1. User testing with Hong Kong caregivers and professional review of questionnaire wording and next-step content.
2. Test voice capture, interruptions and permission flows on physical devices in both languages.
3. Confirm the desired local backup/export/import policy before adding cloud sync.
4. Add multi-child support and report date ranges if required.
5. Design an explicitly consented backend separately if AI follow-up or family sharing is commissioned.
