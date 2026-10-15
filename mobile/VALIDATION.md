# Mobile web verification

## General UI UX pass

15 October 2026: production build and all 5 existing browser suites passed after navigation, typography, recording-action and form layout changes. A 375×812px phone check verified the profile Save action stays on screen while fields scroll and that duplicate top navigation is hidden. Home, Profile and Records screenshots were visually reviewed. Bilingual layouts continue to fit 320/375/414/768px. No business logic, data schema or clinical rules changed.

## Blue reference update

15 October 2026: production TypeScript/Vite build, 7 domain tests and 5 Chromium browser suites passed. The new suites verify stage-gated onboarding across all six stages, optional manual questionnaire access, autosave/skip, immediate regression follow-up and source link, timing notes, English/Traditional Chinese reports, record methods and category-based related entries, persistence/edit/search/delete, older version-one data, and professional report copy fields. Phone layouts across Welcome, Home, Records, Community, Profile and the editor were checked in both languages at 320/375/414/768px. Descriptive subtitles stay absent. Physical-device keyboard dictation, native builds and Safari remain unverified.

The score/severity/inferred-stage results in the reference mockups were deliberately replaced by a response review, following Queenie's brief. Age is entered in years/months; real names, photographs and exact birth dates are not collected.

15 October 2026, Windows / Node 24 / Chromium automated browser checks.

- TypeScript check and Vite production build passed.
- Domain tests cover skipped answers, regression guidance independent of completion, report content, and invalid backup rejection.
- End-to-end flow passed: create profile, create observation, reload persistence, edit, search empty state, questionnaire save/next/review, question 29 immediate follow-up, Traditional Chinese switching, report content, observation deletion.
- Browser render checks passed at 320, 375, 414 and 768 pixels, in both languages; no page horizontal overflow, observation dialog fits.
- Home screen screenshot reviewed at 375px; corrected hidden file input styling and form accessible naming.

Not yet validated: physical devices, Safari/WebKit, OS share sheets, print-to-PDF output on each OS, native Android/iOS builds, keyboard dictation. App store delivery and encrypted native storage are future work. There is no service worker/offline shell in this first web build.
