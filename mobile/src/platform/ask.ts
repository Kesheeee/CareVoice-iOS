export type Suggestion = { type: string; id: string; title: string; plain: string; quote?: string; url?: string; why: string };
export type Safety = { signal: string; route: string; contact?: string };
export type AskResponse = { safety?: Safety; reply?: string; suggestions: Suggestion[]; content_fingerprint?: string };

const BACKEND_URL = (import.meta as any).env?.VITE_BACKEND_URL || "http://localhost:8000";

export const isAskConfigured = true;

export type HistoryMessage = { role: "user" | "assistant"; content: string };

export async function ask(message: string, language: string, history: HistoryMessage[] = []): Promise<AskResponse> {
  const res = await fetch(`${BACKEND_URL}/ask`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ language, message, history }),
  });
  if (!res.ok) {
    const detail = await res.text().catch(() => "");
    throw new Error(`Ask failed (${res.status})${detail ? ": " + detail : ""}`);
  }
  return (await res.json()) as AskResponse;
}
