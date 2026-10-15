# CareVoice mobile design

Reference: UI+UX_1013, Cici UI UX v4. Queenie's onboarding brief governs stage selection and clinical boundaries where mockups conflict.

There is no global top bar, wordmark, top navigation or top-right language control. Each screen begins with its own title, with safe-area padding for phone notches. Navigation lives only at the bottom, and language selection is in Profile.

The app uses one bottom navigation on phones, a prominent home recording action and fixed dialog headers/save actions with independently scrolling fields. Duplicate recording actions are removed; touch targets and supporting text are larger. Records use 24-hour times and a clear empty state.

Home uses a compact white child profile, one blue capture action, two shortcuts (next step and reports), one questionnaire count row and recent records. Duplicate completion displays and monthly statistics cards are removed from Home. The app retains blue bottom navigation. Records use timestamped cards and explicit same-category links. No fabricated demo records, phone frames, decorative subtitles, clinical scoring or inferred stages.

Primary blue is #1565c0, with #0d47a1 for hover and #e3f2fd for pale surfaces. Exact OKLCH equivalents and all other portable tokens live in `src/tokens.css`. System fonts follow the ZIP, with PingFang HK and Traditional Chinese fallbacks. Spacing follows a four-point scale; corner radii are 8–18px. Navigation, forms and dialogs share this system. Motion is limited to pressed controls; reduced motion is supported.

Welcome → optional nickname and age in years/months → six caregiver-selected stages → questionnaire introduction only for the just-noticing stage → answers/review → Home. Other stages go directly Home. Questionnaire remains available from Profile. All questions permit Not sure and Skip. Loss-of-skills Yes/Not sure immediately surfaces official professional follow-up, without a score or interpretation. Clinical details may only be copied from an existing professional report.

Subtitles remain absent in both languages. Form labels, record metadata, progress, privacy notices, safety guidance and source dates are functional content and remain visible.

Storage version 1 is retained. Newly added report fields and regression timing notes are optional; older records/backups remain supported. Native UI packaging continues through Capacitor.

## Exports

### CSS tokens

```css
:root {
  --color-paper: oklch(0.97845987 0.00453078 258.324487);
  --color-surface: oklch(0.99999999 0.00000004 89.875563);
  --color-ink: oklch(0.22843817 0.03842926 282.932396);
  --color-muted: oklch(0.49038881 0.02310953 260.140401);
  --color-line: oklch(0.92618601 0.01090889 256.697057);
  --color-accent: oklch(0.51340082 0.16028197 255.673341);
  --color-accent-hover: oklch(0.42171694 0.15692414 259.913273);
  --color-soft: oklch(0.95324998 0.02178313 239.42747);
  --color-blue: oklch(0.51340082 0.16028197 255.673341);
  --color-blue-soft: oklch(0.95324998 0.02178313 239.42747);
  --color-sand: oklch(0.96853152 0.02815715 79.479552);
  --color-gold: oklch(0.56872599 0.1487592 50.754209);
  --color-danger: oklch(0.50128208 0.17831791 28.704727);
  --color-danger-soft: oklch(0.96885997 0.01521628 22.394961);
  --color-backdrop: oklch(20% 0.025 170 / 0.42);
  --color-shadow: oklch(22% 0.03 170 / 0.06);
  --color-focus: oklch(50% 0.14 250);
  --color-success: oklch(0.5234322 0.13465905 144.167224);
  --color-success-soft: oklch(0.95714927 0.02099289 147.636004);
  --color-pink-soft: oklch(0.94050844 0.0281922 355.436664);
  --color-purple-soft: oklch(0.93702364 0.02100773 304.023978);
  --font-display:
    -apple-system, BlinkMacSystemFont, "PingFang HK", "PingFang TC", "Segoe UI",
    "Microsoft JhengHei", "Helvetica Neue", sans-serif;
  --font-body:
    -apple-system, BlinkMacSystemFont, "PingFang HK", "PingFang TC", "Segoe UI",
    "Microsoft JhengHei", "Helvetica Neue", sans-serif;
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-xl: 32px;
  --space-2xl: 48px;
  --text-sm: 0.8rem;
  --text-body: 0.9375rem;
  --text-display: clamp(2.15rem, 6.8vw, 2.8rem);
  --radius-sm: 12px;
  --radius-md: 12px;
  --radius-lg: 18px;
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-in: cubic-bezier(0.7, 0, 0.84, 0);
  --ease-in-out: cubic-bezier(0.65, 0, 0.35, 1);
  --dur-fast: 140ms;
}
```

### Tailwind v4

```css
@theme inline {
  --color-primary: var(--color-accent);
  --color-background: var(--color-paper);
  --color-foreground: var(--color-ink);
  --color-border: var(--color-line);
  --font-sans: var(--font-body);
  --radius-card: var(--radius-lg);
}
```

### DTCG token pipeline

```json
{
  "carevoice": {
    "primary": {
      "$type": "color",
      "$value": {
        "colorSpace": "oklch",
        "components": [0.51340082, 0.16028197, 255.673341]
      }
    },
    "surface": {
      "$type": "color",
      "$value": {
        "colorSpace": "srgb",
        "components": [1, 1, 1]
      }
    },
    "cardRadius": {
      "$type": "dimension",
      "$value": {
        "value": 18,
        "unit": "px"
      }
    }
  }
}
```

### shadcn variables

```css
:root {
  --background: var(--color-paper);
  --foreground: var(--color-ink);
  --primary: var(--color-accent);
  --primary-foreground: var(--color-surface);
  --card: var(--color-surface);
  --card-foreground: var(--color-ink);
  --muted: var(--color-blue-soft);
  --muted-foreground: var(--color-muted);
  --border: var(--color-line);
  --ring: var(--color-focus);
  --radius: 12px;
}
```
