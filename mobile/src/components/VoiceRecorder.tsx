import { BrowserVoiceRecorder } from "./BrowserVoiceRecorder";
import { translator } from "../i18n";
import { useEffect, useRef, useState } from "react";
import { Mic, Square, Upload } from "lucide-react";
import type { Language } from "../domain";
import { transcribe, TranscriptionError } from "../platform/transcribe";

import { AudioFileError } from "../platform/wav";

const VOICE_LIMIT_SECONDS = 60;
type Status = "idle" | "requesting" | "listening" | "transcribing" | "review" | "error";
type ErrorKey = "unsupported" | "permission" | "microphone" | "network" | "no-speech" | "timeout" | "unknown" | "auth" | "unconfigured" | "rate-limit" | "file-size" | "file-duration" | "file-format" | "file-type";

const errors: Record<ErrorKey, [string, string]> = {
  "file-type": ["Choose an audio file: MP3, M4A, WAV, AAC or FLAC. Photos and videos aren’t supported.", "請選擇 MP3、M4A、WAV、AAC 或 FLAC 音訊檔案，不支援相片及影片。"],
  "file-size": ["Choose an audio file smaller than 20 MB.", "請選擇小於 20 MB 嘅音訊檔案。"],
  "file-duration": ["Choose a clip up to 60 seconds. Trim longer recordings first.", "請選擇不超過 60 秒嘅錄音，較長錄音請先剪輯。"],
  "file-format": ["This file couldn’t be read. Try an MP3, M4A or WAV audio file.", "未能讀取檔案，請試用 MP3、M4A 或 WAV 音訊檔案。"],
  auth: ["Sign in to use voice recording. You can still type your record.", "請先登入使用語音記錄，你仍可輸入文字。"],
  unconfigured: ["Voice transcription is being set up. Please use Text record for now.", "語音轉寫服務設定中，請暫時使用文字記錄。"],
  "rate-limit": ["The speech service is busy. Please try again shortly.", "語音服務繁忙，請稍後再試。"],
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

  const fileInputRef = useRef<HTMLInputElement>(null);
  const [fileName, setFileName] = useState("");

  const callbacks = useRef({ onTranscript, onActiveChange, text });
  callbacks.current = { onTranscript, onActiveChange, text };
  const streamRef = useRef<MediaStream | null>(null);
  const recorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<number | null>(null);
  const baseTextRef = useRef("");
  const cancelledRef = useRef(false);
  const requestRef = useRef<AbortController | null>(null);
  const generationRef = useRef(0);

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
  useEffect(() => () => { cancelledRef.current = true; generationRef.current++; requestRef.current?.abort(); clearTimer(); stopRecorder(); stopStream(); setActive(false); }, []);

  const finish = async (generation: number, mimeType: string, uploadedFile?: File) => {
    if (cancelledRef.current || generation !== generationRef.current) return;
    clearTimer();
    stopStream();
    recorderRef.current = null;
    const blob = uploadedFile || new Blob(chunksRef.current, { type: mimeType });
    chunksRef.current = [];
    setStatus("transcribing");
    const controller = new AbortController();
    requestRef.current = controller;
    const timeout = window.setTimeout(() => controller.abort(), 60000);
    try {
      const result = await transcribe(blob, locale, controller.signal, !!uploadedFile);
      if (cancelledRef.current || generation !== generationRef.current) return;
      const got = (result.text || "").trim();
      if (!got) { setStatus("error"); setError("no-speech"); setActive(false); return; }
      const separator = baseTextRef.current && got ? "\n" : "";
      callbacks.current.onTranscript((baseTextRef.current + separator + got).slice(0, 10000));
      setStatus("review"); setActive(false);
    } catch (e) {
      if (cancelledRef.current || generation !== generationRef.current) return;
      const code = e instanceof TranscriptionError || e instanceof AudioFileError ? e.code : controller.signal.aborted ? "timeout" : "network";
      setStatus("error"); setError(code in errors ? code as ErrorKey : "network"); setActive(false);
    } finally { window.clearTimeout(timeout); }
  };

  const upload = (file?: File) => {
    if (!file || busy) return;
    const generation = ++generationRef.current;
    cancelledRef.current = false;
    baseTextRef.current = callbacks.current.text.trimEnd();
    setFileName(file.name); setError(null); setSeconds(0); setActive(true);
    void finish(generation, file.type, file);
  };

  const start = async () => {
    if (busy) return;
    const generation = ++generationRef.current;
    cancelledRef.current = false;
    baseTextRef.current = callbacks.current.text.trimEnd();
    setError(null); setSeconds(0); setFileName("");
    setStatus("requesting"); setActive(true);
    try {
      if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === "undefined") {
        throw Object.assign(new Error("unsupported"), { name: "unsupported" });
      }
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      if (cancelledRef.current || generation !== generationRef.current) { stream.getTracks().forEach((track) => track.stop()); return; }
      streamRef.current = stream;
      const mimeType = MIME_OPTIONS.find((mt) => MediaRecorder.isTypeSupported(mt)) || "";
      const recorder = mimeType ? new MediaRecorder(stream, { mimeType }) : new MediaRecorder(stream);
      recorderRef.current = recorder;
      chunksRef.current = [];
      recorder.ondataavailable = (e) => { if (generation === generationRef.current && e.data && e.data.size > 0) chunksRef.current.push(e.data); };
      recorder.onerror = () => {
        if (generation !== generationRef.current) return;
        cancelledRef.current = true; generationRef.current++; clearTimer(); stopRecorder(); stopStream();
        setStatus("error"); setError("microphone"); setActive(false);
      };
      recorder.onstop = () => { void finish(generation, recorder.mimeType); };
      recorder.start();
      setStatus("listening");
      const startedAt = Date.now();
      timerRef.current = window.setInterval(() => {
        const s = Math.floor((Date.now() - startedAt) / 1000);
        setSeconds(Math.min(VOICE_LIMIT_SECONDS, s));
        if (s >= VOICE_LIMIT_SECONDS) stop();
      }, 250);
    } catch (e) {
      if (generation !== generationRef.current || cancelledRef.current) return;
      stopStream();
      setStatus("error"); setActive(false);
      const name = e instanceof Error ? e.name : "";
      setError(name === "unsupported" ? "unsupported" : name === "NotAllowedError" || name === "SecurityError" ? "permission" : name === "NotFoundError" ? "microphone" : "microphone");
    }
  };

  const stop = () => {
    if (status === "requesting") { cancelledRef.current = true; generationRef.current++; stopStream(); setStatus("idle"); setActive(false); return; }
    const r = recorderRef.current;
    if (!r || r.state === "inactive") return;
    clearTimer();
    setStatus("transcribing");
    try { r.stop(); } catch { setStatus("error"); setError("unknown"); setActive(false); }
  };

  const cancel = () => { cancelledRef.current = true; generationRef.current++; requestRef.current?.abort(); clearTimer(); stopRecorder(); stopStream(); setStatus("idle"); setError(null); setActive(false); };

  const statusLabel = () => {
    switch (status) {
      case "listening": return t("Listening…", "聆聽中……");
      case "requesting": return t("Waiting for microphone permission…", "等候咪高峰權限……");
      case "transcribing": return t("Transcribing…", "正在轉寫文字……");
      case "review": return t("Ready to review. Check the text below before saving.", "文字已準備好，請核對後再儲存。");
      default: return null;
    }
  };

  return <div className="quick-voice-intro voice-recorder">
    <span className="quick-voice-symbol"><Mic size={36} aria-hidden="true" /></span>
    <label className="voice-language">{t("Recording language", "錄音語言")}
      <select aria-label={t("Recording language", "錄音語言")} disabled={busy} value={locale} onChange={(event) => setLocale(event.target.value)}>
        <option value="en-US">English</option><option value="zh-HK">廣東話</option><option value="zh-CN">普通话</option>
      </select>
    </label>
    {fileName && <p className="voice-file-name">{fileName}</p>}
    {statusLabel() && <p className="voice-progress" role="status">{statusLabel()}</p>}
    {status === "listening" && <output className="voice-timer" aria-label={t("Recording time", "錄音時間")}>{`${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")} / 1:00`}</output>}
    {error && <p className="voice-error" role="alert">{t(...errors[error])}</p>}
    {status === "transcribing" && <button type="button" className="secondary full" onClick={cancel}>{t("Cancel transcription", "取消轉寫")}</button>}
    {status !== "transcribing" && (busy ? <button type="button" className="primary full" onClick={stop}>
      <Square size={16} aria-hidden="true" />{status === "requesting" ? t("Cancel request", "取消請求") : t("Stop recording", "停止錄音")}
    </button> : <button type="button" className="primary full" onClick={start}>
      <Mic size={18} aria-hidden="true" />{error ? t("Try again", "再試一次") : status === "review" ? t("Record more", "繼續錄音") : t("Start recording", "開始錄音")}
    </button>)}
    <input ref={fileInputRef} type="file" hidden accept=".mp3,.m4a,.wav,.aac,.flac" aria-label={t("Choose audio file", "選擇音訊檔案")} onChange={(event) => { const file = event.target.files?.[0]; event.target.value = ""; upload(file); }}/>
    {!busy && <button type="button" className="secondary full voice-upload" onClick={() => fileInputRef.current?.click()}><Upload size={18} aria-hidden="true" />{t("Upload audio", "上傳錄音")}</button>}
    {!busy && <small className="voice-upload-limit">{t("Up to 60 seconds · 20 MB", "最長 60 秒 · 20 MB")}</small>}
  </div>;
}

// Supabase transcription is deployed and verified. Browser speech is an explicit fallback.
export function VoiceRecorder(props: Parameters<typeof AzureVoiceRecorder>[0]) {
  return (import.meta as ImportMeta & { env?: { VITE_VOICE_BACKEND?: string } }).env?.VITE_VOICE_BACKEND !== "browser"
    ? <AzureVoiceRecorder {...props}/>
    : <BrowserVoiceRecorder {...props}/>;
}
