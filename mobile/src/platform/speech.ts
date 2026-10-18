export type VoiceStatus = "idle" | "requesting" | "listening" | "stopping" | "review" | "error";
export type VoiceError = "unsupported" | "permission" | "microphone" | "network" | "language" | "no-speech" | "timeout" | "unknown";
export type VoiceState = { status: VoiceStatus; seconds: number; interim: string; error?: VoiceError };
export type SpeechResult = { isFinal: boolean; 0: { transcript: string } };
export interface SpeechEngine {
  lang: string;
  continuous: boolean;
  interimResults: boolean;
  maxAlternatives: number;
  onstart: (() => void) | null;
  onresult: ((event: { results: ArrayLike<SpeechResult> }) => void) | null;
  onerror: ((event: { error: string }) => void) | null;
  onend: (() => void) | null;
  start(): void;
  stop(): void;
  abort(): void;
}
export type SpeechFactory = () => SpeechEngine;
export const VOICE_LIMIT_SECONDS = 60;

export function browserSpeechFactory(): SpeechFactory | undefined {
  if (typeof window === "undefined" || !window.isSecureContext) return;
  const scope = window as unknown as {
    SpeechRecognition?: new () => SpeechEngine;
    webkitSpeechRecognition?: new () => SpeechEngine;
  };
  const Engine = scope.SpeechRecognition ?? scope.webkitSpeechRecognition;
  return Engine ? () => new Engine() : undefined;
}

function voiceError(code: string): VoiceError {
  if (["not-allowed", "service-not-allowed", "NotAllowedError", "SecurityError"].includes(code)) return "permission";
  if (["audio-capture", "NotFoundError", "NotReadableError"].includes(code)) return "microphone";
  if (code === "network") return "network";
  if (code === "language-not-supported") return "language";
  if (code === "no-speech") return "no-speech";
  return "unknown";
}

// The browser owns microphone permission and speech processing. We retain text only.
// Rebuild cumulative results to avoid duplicating interim revisions and final phrases.
export class VoiceSession {
  private engine?: SpeechEngine;
  private ticker?: ReturnType<typeof setInterval>;
  private deadline?: ReturnType<typeof setTimeout>;
  private watchdog?: ReturnType<typeof setTimeout>;
  private state: VoiceState = { status: "idle", seconds: 0, interim: "" };
  private transcript = "";
  private startedAt = 0;
  private readonly factory: SpeechFactory | undefined;
  private readonly onState: (state: VoiceState) => void;
  private readonly onTranscript: (text: string) => void;

  constructor(
    factory: SpeechFactory | undefined,
    onState: (state: VoiceState) => void,
    onTranscript: (text: string) => void,
  ) { this.factory = factory; this.onState = onState; this.onTranscript = onTranscript; }

  private publish(patch: Partial<VoiceState>) {
    this.state = { ...this.state, ...patch };
    this.onState({ ...this.state });
  }
  private clearTimers() {
    clearInterval(this.ticker); clearTimeout(this.deadline); clearTimeout(this.watchdog);
    this.ticker = undefined; this.deadline = undefined; this.watchdog = undefined;
  }
  private release() {
    this.clearTimers();
    const engine = this.engine;
    this.engine = undefined;
    if (engine) {
      engine.onstart = engine.onresult = engine.onerror = engine.onend = null;
      try { engine.abort(); } catch { /* An already-ended engine needs no cleanup. */ }
    }
  }
  private fail(error: VoiceError) {
    this.release();
    this.publish({ status: "error", error, interim: "" });
  }
  start(language: string) {
    if (this.engine) return;
    this.transcript = "";
    this.publish({ status: "requesting", seconds: 0, interim: "", error: undefined });
    if (!this.factory) { this.fail("unsupported"); return; }
    try {
      const engine = this.factory();
      this.engine = engine;
      engine.lang = language;
      engine.continuous = true;
      engine.interimResults = true;
      engine.maxAlternatives = 1;
      engine.onstart = () => {
        if (this.engine !== engine || this.state.status !== "requesting") return;
        clearTimeout(this.watchdog);
        this.startedAt = Date.now();
        this.publish({ status: "listening" });
        this.ticker = setInterval(() => {
          this.publish({ seconds: Math.min(VOICE_LIMIT_SECONDS, Math.floor((Date.now() - this.startedAt) / 1000)) });
        }, 250);
        this.deadline = setTimeout(() => {
          this.publish({ seconds: VOICE_LIMIT_SECONDS });
          this.stop();
        }, VOICE_LIMIT_SECONDS * 1000);
      };
      engine.onresult = event => {
        if (this.engine !== engine) return;
        const results = Array.from(event.results);
        const final = results.filter(result => result.isFinal).map(result => result[0].transcript.trim()).filter(Boolean).join(" ");
        const interim = results.filter(result => !result.isFinal).map(result => result[0].transcript.trim()).filter(Boolean).join(" ");
        if (final !== this.transcript) {
          this.transcript = final;
          this.onTranscript(final);
        }
        this.publish({ interim });
      };
      engine.onerror = event => { if (this.engine === engine) this.fail(voiceError(event.error)); };
      engine.onend = () => {
        if (this.engine !== engine) return;
        this.release();
        this.publish({ status: this.transcript ? "review" : "error", error: this.transcript ? undefined : "no-speech", interim: "" });
      };
      // Do not leave a pending permission request or a stalled provider active indefinitely.
      this.watchdog = setTimeout(() => this.fail("timeout"), 30000);
      engine.start();
    } catch (error) {
      this.fail(voiceError(error instanceof Error ? error.name : "unknown"));
    }
  }
  stop() {
    const engine = this.engine;
    if (!engine || this.state.status === "stopping") return;
    if (this.state.status === "requesting") { this.cancel(); return; }
    this.clearTimers();
    this.publish({ status: "stopping", interim: "" });
    // stop() permits the provider's final result. Never save a record automatically.
    this.watchdog = setTimeout(() => {
      this.release();
      this.publish({ status: "error", error: "timeout", interim: "" });
    }, 8000);
    try { engine.stop(); } catch { this.fail("unknown"); }
  }
  cancel() {
    this.release();
    this.publish({ status: "idle", interim: "", error: undefined });
  }
  dispose() { this.release(); }
}
