import { BrowserVoiceRecorder } from "./BrowserVoiceRecorder";
import { translator } from "../i18n";
import { useEffect, useRef, useState } from "react";
import { Mic, Square } from "lucide-react";
import type { Language } from "../domain";
import { transcribe } from "../platform/transcribe";

const VOICE_LIMIT_SECONDS = 60;
type Status = "idle" | "requesting" | "listening" | "transcribing" | "review" | "error";
type ErrorKey = "unsupported" | "permission" | "microphone" | "network" | "no-speech" | "timeout" | "unknown";

const errors: Record<ErrorKey, [string, string]> = {
  unsupported: ["Recording isn’t available in this browser. Use Text record instead.", "呢個瀏覽器未支援錄音。請改用文字記錄。"],
  permission: ["Microphone access was blocked. Allow access in your browser settings, then try again.", "咪高峰權限被封鎖。請喺瀏覽器設定允許使用，再試一次。"],
  microphone: ["The microphone isn’t available. Check its connection or close other apps using it, then retry.", "未能使用咪高峰。請檢查連接，或者關閉其他使用咪高峰嘅應用程式，再試一次。"],
  network: ["Transcription couldn’t connect. Check your connection and try again. Your existing text is kept.", "未能連接轉寫服務。請檢查網絡再試一次，已有文字會保留。"],
  "no-speech": ["No speech was recognised. Try again and speak clearly, or type your observation.", "未辨識到語音。請再試一次並清楚講話，或者輸入文字。"],
  timeout: ["Recording or transcription took too long. Review any text below before retrying.", "錄音或轉寫逾時。再試之前請核對下方已有嘅文字。"],
  unknown: ["Voice entry stopped unexpectedly. Your existing text is kept.", "語音輸入意外停止，已有文字會保留。"],
};

const MIME_OPTIONS = ["audio/webm", "audio/mp4", "audio/ogg"];

export function AzureVoiceRecorder({ language, text, onTranscript, onActiveChange }: {
  language: Language;
  text: string;
  onTranscript: (text: string) => void;
  onActiveChange: (active: boolean) => void;
}) {
  const zh = language !== "en", t = translator(language);
  const [locale, setLocale] = useState(language === "zh-Hans" ? "zh-CN" : zh ? "zh-HK" : "en-US");
  const [status, setStatus] = useState<Status>("idle");
  const [seconds, setSeconds] = useState(0);
  const [error, setError] = useState<ErrorKey | null>(null);

  const callbacks = useRef({ onTranscript, onActiveChange, text });
  callbacks.current = { onTranscript, onActiveChange, text };
  const streamRef = useRef<MediaStream | null>(null);
  const recorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<number | null>(null);
  const baseTextRef = useRef("");
  const cancelledRef = useRef(false);

  const busy = status === "requesting" || status === "listening" || status === "transcribing";
  const setActive = (active: boolean) => callbacks.current.onActiveChange(active);

  function clearTimer() {
    if (timerRef.current !== null) { window.clearInterval(timerRef.current); timerRef.current = null; }
  }
  function stopStream() {
    const s = streamRef.current;
    if (s) { s.getTracks().forEach((track) => track.stop()); streamRef.current = null; }
  }
  function stopRecorder() {
    const r = recorderRef.current;
    if (r && r.state !== "inactive") { try { r.stop(); } catch { /* already stopped */ } }
    recorderRef.current = null;
  }

  // Tear down on unmount.
  useEffect(() => () => { cancelledRef.current = true; clearTimer(); stopRecorder(); stopStream(); setActive(false); }, []);

  const finish = async () => {
    if (cancelledRef.current) return;
    clearTimer();
    stopStream();
    const mimeType = recorderRef.current?.mimeType || "audio/webm";
    const ext = mimeType.includes("mp4") ? "mp4" : mimeType.includes("ogg") ? "ogg" : "webm";
    recorderRef.current = null;
    const blob = new Blob(chunksRef.current, { type: mimeType });
    chunksRef.current = [];
    setStatus("transcribing");
    try {
      const result = await transcribe(blob, locale, `recording.${ext}`);
      if (cancelledRef.current) return;
      const got = (result.text || "").trim();
      if (!got) { setStatus("error"); setError("no-speech"); setActive(false); return; }
      const separator = baseTextRef.current && got ? "\n" : "";
      callbacks.current.onTranscript((baseTextRef.current + separator + got).slice(0, 10000));
      setStatus("review"); setActive(false);
    } catch {
      if (cancelledRef.current) return;
      setStatus("error"); setError("network"); setActive(false);
    }
  };

  const start = async () => {
    if (busy) return;
    cancelledRef.current = false;
    baseTextRef.current = callbacks.current.text.trimEnd();
    setError(null); setSeconds(0);
    setStatus("requesting"); setActive(true);
    try {
      if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === "undefined") {
        throw Object.assign(new Error("unsupported"), { name: "unsupported" });
      }
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      if (cancelledRef.current) { stream.getTracks().forEach((track) => track.stop()); return; }
      streamRef.current = stream;
      const mimeType = MIME_OPTIONS.find((mt) => MediaRecorder.isTypeSupported(mt)) || "";
      const recorder = mimeType ? new MediaRecorder(stream, { mimeType }) : new MediaRecorder(stream);
      recorderRef.current = recorder;
      chunksRef.current = [];
      recorder.ondataavailable = (e) => { if (e.data && e.data.size > 0) chunksRef.current.push(e.data); };
      recorder.onstop = () => { void finish(); };
      recorder.start();
      setStatus("listening");
      const startedAt = Date.now();
      timerRef.current = window.setInterval(() => {
        const s = Math.floor((Date.now() - startedAt) / 1000);
        setSeconds(Math.min(VOICE_LIMIT_SECONDS, s));
        if (s >= VOICE_LIMIT_SECONDS) stop();
      }, 250);
    } catch (e) {
      setStatus("error"); setActive(false);
      const name = e instanceof Error ? e.name : "";
      setError(name === "unsupported" ? "unsupported" : name === "NotAllowedError" || name === "SecurityError" ? "permission" : name === "NotFoundError" ? "microphone" : "microphone");
    }
  };

  const stop = () => {
    if (status === "requesting") { cancelledRef.current = true; stopStream(); setStatus("idle"); setActive(false); return; }
    const r = recorderRef.current;
    if (!r || r.state === "inactive") return;
    clearTimer();
    setStatus("transcribing");
    try { r.stop(); } catch { setStatus("error"); setError("unknown"); setActive(false); }
  };

  const cancel = () => { cancelledRef.current = true; clearTimer(); stopRecorder(); stopStream(); setStatus("idle"); setError(null); setActive(false); };

  const statusLabel = () => {
    switch (status) {
      case "listening": return t("Listening…", "聆聽中……");
      case "requesting": return t("Waiting for microphone permission…", "等候咪高峰權限……");
      case "transcribing": return t("Transcribing…", "正在轉寫文字……");
      case "review": return t("Ready to review. Check the text below before saving.", "文字已準備好，請核對後再儲存。");
      default: return t("Tap Start recording and speak for up to 60 seconds.", "撳開始錄音，最長可以講 60 秒。");
    }
  };

  return <div className="quick-voice-intro voice-recorder">
    <span className="quick-voice-symbol"><Mic size={36} aria-hidden="true" /></span>
    <label className="voice-language">{t("Recording language", "錄音語言")}
      <select aria-label={t("Recording language", "錄音語言")} disabled={busy} value={locale} onChange={(event) => setLocale(event.target.value)}>
        <option value="en-US">English</option><option value="zh-HK">廣東話</option><option value="zh-CN">普通话</option>
      </select>
    </label>
    <p className="voice-progress" role="status">{statusLabel()}</p>
    {busy && <output className="voice-timer" aria-label={t("Recording time", "錄音時間")}>{`${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")} / 1:00`}</output>}
    {error && <p className="voice-error" role="alert">{t(...errors[error])}</p>}
    {busy ? <button type="button" className="primary full" disabled={status === "transcribing"} onClick={stop}>
      <Square size={16} aria-hidden="true" />{status === "requesting" ? t("Cancel request", "取消請求") : t("Stop recording", "停止錄音")}
    </button> : <button type="button" className="primary full" onClick={start}>
      <Mic size={18} aria-hidden="true" />{error ? t("Try again", "再試一次") : status === "review" ? t("Record more", "繼續錄音") : t("Start recording", "開始錄音")}
    </button>}
    <p className="voice-privacy">{t("Your voice is transcribed by CareVoice’s service and is not stored. Review the text before saving.", "你嘅語音會由 CareVoice 嘅服務轉寫，唔會儲存。儲存前請核對文字。")}</p>
  </div>;
}

// Production retains browser speech entry until a hosted backend is configured.
export function VoiceRecorder(props: Parameters<typeof AzureVoiceRecorder>[0]) {
  return (import.meta as ImportMeta & { env?: { VITE_BACKEND_URL?: string } }).env?.VITE_BACKEND_URL
    ? <AzureVoiceRecorder {...props}/>
    : <BrowserVoiceRecorder {...props}/>;
}
