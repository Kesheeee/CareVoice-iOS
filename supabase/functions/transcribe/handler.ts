const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-speech-language",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
};
const MAX_BYTES = 44 + 16000 * 2 * 60;
type Dependencies = { authenticate: (token: string) => Promise<boolean>; key?: string; region?: string; fetch: typeof fetch };

export function validWav(bytes: Uint8Array): boolean {
  if (bytes.length < 46 || bytes.length > MAX_BYTES || bytes.length % 2 !== 0) return false;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const text = (start: number, end: number) => new TextDecoder().decode(bytes.slice(start, end));
  return text(0, 4) === "RIFF" && text(8, 12) === "WAVE" && text(12, 16) === "fmt "
    && text(36, 40) === "data" && view.getUint32(4, true) === bytes.length - 8
    && view.getUint32(16, true) === 16 && view.getUint16(20, true) === 1
    && view.getUint16(22, true) === 1 && view.getUint32(24, true) === 16000
    && view.getUint32(28, true) === 32000 && view.getUint16(32, true) === 2
    && view.getUint16(34, true) === 16 && view.getUint32(40, true) === bytes.length - 44;
}

export function createHandler(deps: Dependencies) {
  const reply = (status: number, body: unknown) => Response.json(body, { status, headers: cors });
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
    if (req.method !== "POST") return reply(405, { code: "method" });
    try {
      const token = req.headers.get("authorization")?.match(/^Bearer (.+)$/i)?.[1];
      if (!token || !await deps.authenticate(token)) return reply(401, { code: "auth" });
      const language = req.headers.get("x-speech-language") || "en-US";
      if (!["en-US", "zh-HK", "zh-CN"].includes(language)) return reply(400, { code: "language" });
      if (req.headers.get("content-type")?.split(";")[0] !== "audio/wav") return reply(415, { code: "format" });
      if (!deps.key || !deps.region || !/^[a-z0-9-]+$/.test(deps.region)) return reply(503, { code: "unconfigured" });
      if (Number(req.headers.get("content-length")) > MAX_BYTES) return reply(413, { code: "too-large" });
      const reader = req.body?.getReader();
      if (!reader) return reply(400, { code: "format" });
      const chunks: Uint8Array[] = []; let length = 0;
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        length += value.length;
        if (length > MAX_BYTES) { await reader.cancel(); return reply(413, { code: "too-large" }); }
        chunks.push(value);
      }
      const audio = new Uint8Array(length); let offset = 0;
      for (const chunk of chunks) { audio.set(chunk, offset); offset += chunk.length; }
      if (!validWav(audio)) return reply(400, { code: "format" });
      const response = await deps.fetch(`https://${deps.region}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=${language}`, {
        method: "POST", body: audio,
        headers: { "Ocp-Apim-Subscription-Key": deps.key, "Content-Type": "audio/wav; codecs=audio/pcm; samplerate=16000" },
        signal: AbortSignal.timeout(45000),
      });
      if (!response.ok) return reply(response.status === 429 ? 429 : 502, { code: response.status === 429 ? "rate-limit" : "provider" });
      const result = await response.json();
      if (!["Success", "NoMatch", "InitialSilenceTimeout"].includes(result.RecognitionStatus)) return reply(502, { code: "provider" });
      return reply(200, { text: result.RecognitionStatus === "Success" ? String(result.DisplayText || "") : "", language, status: result.RecognitionStatus });
    } catch (error) {
      const timeout = error instanceof Error && error.name === "TimeoutError";
      return reply(timeout ? 504 : 502, { code: timeout ? "timeout" : "network" });
    }
  };
}
