export type TranscribeResult = { text: string; language: string; status?: string };

// Dev default points at the local FastAPI backend. Override at build time with
// VITE_BACKEND_URL (e.g. the deployed backend for the demo).
const BACKEND_URL = (import.meta as any).env?.VITE_BACKEND_URL || "http://localhost:8000";

export async function transcribe(
  audio: Blob,
  language: string,
  filename = "recording.webm",
): Promise<TranscribeResult> {
  const form = new FormData();
  form.append("audio", audio, filename);
  form.append("language", language);
  const res = await fetch(`${BACKEND_URL}/transcribe`, { method: "POST", body: form });
  if (!res.ok) {
    const detail = await res.text().catch(() => "");
    throw new Error(`Transcription failed (${res.status})${detail ? ": " + detail : ""}`);
  }
  return (await res.json()) as TranscribeResult;
}
