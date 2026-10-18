import { translator } from "../i18n";
import { useEffect, useRef, useState } from "react";
import { Mic, Square } from "lucide-react";
import type { Language } from "../domain";
import { browserSpeechFactory, VoiceSession, type VoiceError, type VoiceState } from "../platform/speech";

const errors: Record<VoiceError, [string, string]> = {
  unsupported: ["Voice recognition isn’t available in this browser. Try Safari on iPhone or Chrome, or choose Text record.", "呢個瀏覽器未支援語音辨識。請用 iPhone Safari 或 Chrome，或者選擇文字記錄。"],
  permission: ["Microphone or speech access was blocked. Allow access in your browser settings, then try again.", "咪高峰或語音權限被封鎖。請喺瀏覽器設定允許使用，再試一次。"],
  microphone: ["The microphone isn’t available. Check its connection or close other apps using it, then retry.", "未能使用咪高峰。請檢查連接，或者關閉其他使用咪高峰嘅應用程式，再試一次。"],
  network: ["The speech service couldn’t connect. Check your internet connection and try again. Your existing text is kept.", "未能連接語音服務。請檢查網絡再試一次，已有文字會保留。"],
  language: ["The speech service doesn’t support this language. Choose another recording language or use Text record.", "語音服務未支援呢種語言。請選擇其他錄音語言，或者使用文字記錄。"],
  "no-speech": ["No speech was recognised. Try again and speak clearly, or type your observation.", "未辨識到語音。請再試一次並清楚講話，或者輸入文字。"],
  timeout: ["The speech service took too long to respond. Recording has stopped. Review any text below before retrying.", "語音服務回應逾時，已停止錄音。再試之前請核對下方已有嘅文字。"],
  unknown: ["Voice entry stopped unexpectedly. Your existing text is kept; you can try again or type instead.", "語音輸入意外停止，已有文字會保留。你可以再試一次，或者使用文字輸入。"],
};

export function VoiceRecorder({ language, text, onTranscript, onActiveChange }: {
  language: Language;
  text: string;
  onTranscript: (text: string) => void;
  onActiveChange: (active: boolean) => void;
}) {
  const zh = language !== "en", t = translator(language);
  const [locale, setLocale] = useState(language === "zh-Hans" ? "zh-CN" : zh ? "zh-HK" : "en-US");
  const [state, setState] = useState<VoiceState>({ status: "idle", seconds: 0, interim: "" });
  const callbacks = useRef({ onTranscript, onActiveChange, text });
  callbacks.current = { onTranscript, onActiveChange, text };
  const session = useRef<VoiceSession | null>(null);
  const baseText = useRef("");
  const busy = ["requesting", "listening", "stopping"].includes(state.status);
  useEffect(() => {
    const controller = new VoiceSession(browserSpeechFactory(), next => {
      setState(next);
      callbacks.current.onActiveChange(["requesting", "listening", "stopping"].includes(next.status));
    }, transcript => {
      const separator = baseText.current && transcript ? "\n" : "";
      callbacks.current.onTranscript((baseText.current + separator + transcript).slice(0, 10000));
    });
    session.current = controller;
    const stopOnHide = () => { if (document.hidden) controller.stop(); };
    const cancelOnLeave = () => controller.cancel();
    document.addEventListener("visibilitychange", stopOnHide);
    window.addEventListener("pagehide", cancelOnLeave);
    return () => {
      controller.dispose(); session.current = null;
      callbacks.current.onActiveChange(false);
      document.removeEventListener("visibilitychange", stopOnHide);
      window.removeEventListener("pagehide", cancelOnLeave);
    };
  }, []);
  const start = () => {
    if (busy) return;
    baseText.current = callbacks.current.text.trimEnd();
    session.current?.start(locale);
  };
  return <div className={`quick-voice-intro voice-recorder voice-${state.status}`}>
    <span className="quick-voice-symbol"><Mic size={36} aria-hidden="true" /></span>
    <label className="voice-language">{t("Recording language", "錄音語言")}
      <select aria-label={t("Recording language", "錄音語言")} disabled={busy} value={locale} onChange={event => setLocale(event.target.value)}>
        <option value="en-US">English</option><option value="zh-HK">廣東話</option><option value="zh-CN">普通话</option>
      </select>
    </label>
    <p className="voice-progress" role="status">{state.status === "listening" ? t("Listening…", "聆聽中……") : state.status === "requesting" ? t("Waiting for microphone permission…", "等候咪高峰權限……") : state.status === "stopping" ? t("Finishing transcription…", "正在完成文字轉換……") : state.status === "review" ? t("Ready to review. Check the text below before saving.", "文字已準備好，請核對後再儲存。") : t("Tap Start recording and speak for up to 60 seconds.", "撳開始錄音，最長可以講 60 秒。")}</p>
    {busy && <output className="voice-timer" aria-label={t("Recording time", "錄音時間")}>{`${Math.floor(state.seconds / 60)}:${String(state.seconds % 60).padStart(2, "0")} / 1:00`}</output>}
    {state.interim && <p className="voice-interim">{state.interim}</p>}
    {state.error && <p className="voice-error" role="alert">{t(...errors[state.error])}</p>}
    {busy ? <button type="button" className="primary full" disabled={state.status === "stopping"} onClick={() => session.current?.stop()}>
      <Square size={16} aria-hidden="true" />{state.status === "requesting" ? t("Cancel request", "取消請求") : t("Stop recording", "停止錄音")}
    </button> : <button type="button" className="primary full" onClick={start}>
      <Mic size={18} aria-hidden="true" />{state.error ? t("Try again", "再試一次") : state.status === "review" ? t("Record more", "繼續錄音") : t("Start recording", "開始錄音")}
    </button>}
    <p className="voice-privacy">{t("Your browser’s speech service processes your voice. CareVoice saves only the text you review, not an audio file.", "語音由瀏覽器嘅語音服務處理。CareVoice 只儲存你核對後嘅文字，唔會儲存錄音檔案。")}</p>
  </div>;
}
