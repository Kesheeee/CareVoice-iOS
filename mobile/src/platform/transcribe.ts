import { authClient } from "./auth";
import { recordingToWav } from "./wav";
export type TranscribeResult = { text: string; language: string; status?: string };

// Credentials remain in Supabase; the browser sends only its user session.
export class TranscriptionError extends Error {
  code: string;
  constructor(code: string) { super(code); this.code = code; }
}

export async function transcribe(
  audio: Blob,
  language: string,
  signal?: AbortSignal, uploaded = false,
): Promise<TranscribeResult> {
  const { data: { session } } = await authClient.auth.getSession();
  if (!session) throw new TranscriptionError("auth");
  const wav = await recordingToWav(audio, uploaded);
  signal?.throwIfAborted();
  const { data, error } = await authClient.functions.invoke("transcribe", {
    body: wav, headers: { "Content-Type": "audio/wav", "x-speech-language": language }, signal,
  });
  if (error) {
    const response = (error as { context?: Response }).context;
    const body = response instanceof Response ? await response.json().catch(() => null) : null;
    throw new TranscriptionError(body?.code || (response?.status === 401 ? "auth" : "network"));
  }
  if (!data || typeof data.text !== "string") throw new TranscriptionError("network");
  return data as TranscribeResult;
}
