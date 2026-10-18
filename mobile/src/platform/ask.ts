export type Suggestion = {
  type: string;
  id: string;
  title: string;
  plain: string;
  quote?: string;
  url?: string;
  why: string;
};
export type Safety = { signal: string; route: string; contact?: string };
export type AskResponse = {
  safety?: Safety;
  suggestions: Suggestion[];
  content_fingerprint?: string;
};

const env = (import.meta as any).env;
const BACKEND_URL = (env?.VITE_BACKEND_URL || (env?.DEV ? "http://localhost:8000" : "")).replace(/\/$/, "");
export const isAskConfigured = Boolean(BACKEND_URL);

export async function ask(message: string, language: string): Promise<AskResponse> {
  if (!isAskConfigured) throw new Error("CareVoice AI backend is not configured");
  const res = await fetch(`${BACKEND_URL}/ask`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ language, message }),
    signal: AbortSignal.timeout(60000),
  });
  if (!res.ok) {
    const detail = await res.text().catch(() => "");
    throw new Error(`Ask failed (${res.status})${detail ? ": " + detail : ""}`);
  }
  return (await res.json()) as AskResponse;
}
