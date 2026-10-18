// Solid counterparts for the four outline navigation icons.
export function SelectedTabIcon({ tab }: { tab: "home" | "records" | "resources" | "profile" }) {
  return <svg width="23" height="23" viewBox="0 0 24 24" fill="currentColor" stroke="none" aria-hidden="true">
    {tab === "home" && <path d="M10.7 2.8a2 2 0 0 1 2.6 0l7 6A2 2 0 0 1 21 10.3V20a2 2 0 0 1-2 2h-4v-8H9v8H5a2 2 0 0 1-2-2v-9.7a2 2 0 0 1 .7-1.5z" />}
    {tab === "records" && <><path d="M3 3h4a7 7 0 0 1 4 1.3V22a7 7 0 0 0-4-1.3H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Z" /><path d="M21 3h-4a7 7 0 0 0-4 1.3V22a7 7 0 0 1 4-1.3h4a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2Z" /></>}
    {tab === "resources" && <><circle cx="9" cy="7" r="4" /><path d="M2 21v-3a7 7 0 0 1 14 0v3ZM16 3a4 4 0 0 1 0 8 6 6 0 0 0 0-8ZM18 12a7 7 0 0 1 5 6v3h-5v-3a9 9 0 0 0-2-5.7Z" /></>}
    {tab === "profile" && <path fillRule="evenodd" d="m10 1-1 3-2 .8L4 4 1 9l2 2v2l-2 2 3 5 3-.8 2 .8 1 3h4l1-3 2-.8 3 .8 3-5-2-2v-2l2-2-3-5-3 .8-2-.8-1-3ZM12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8Z" />}
  </svg>;
}
