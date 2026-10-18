import { translator } from "../i18n";
import { useEffect, useRef, useState, type FormEvent } from "react";
import { ArrowLeft, Eye, EyeOff, Mail, LockKeyhole } from "lucide-react";
import { SignInVideo } from "./SignInVideo";
import { authClient, authErrorMessage, sendSignInEmail } from "../platform/auth";
import type { Language } from "../domain";
import "../sign-in.css";

export function SignIn({ language, onBack, onContinue, embedded = false, emailOnly = false }: {
  emailOnly?: boolean; embedded?: boolean; language: Language;
  onBack: () => void; onContinue: () => void;
}) {
  const t = translator(language);
  const [visible, setVisible] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [code, setCode] = useState("");
  const [sentTo, setSentTo] = useState("");
  const [showCode, setShowCode] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [remaining, setRemaining] = useState(0);
  const [resendAt, setResendAt] = useState(0);
  const [linkMode, setLinkMode] = useState(emailOnly);
  const mounted = useRef(true);
  const requestInFlight = useRef(false);
  useEffect(() => { mounted.current = true; return () => { mounted.current = false; }; }, []);
  useEffect(() => {
    const tick = () => setRemaining(Math.max(0, Math.ceil((resendAt - Date.now()) / 1000)));
    tick();
    const timer = window.setInterval(tick, 1000);
    return () => window.clearInterval(timer);
  }, [resendAt]);
  async function run(action: () => Promise<void>) {
    if (requestInFlight.current) return;
    requestInFlight.current = true;
    setBusy(true); setError("");
    try { await action(); }
    catch (cause) { if (mounted.current) setError(authErrorMessage(cause, language)); }
    finally { requestInFlight.current = false; if (mounted.current) setBusy(false); }
  }
  async function sendLink() {
    const address = (sentTo || email).trim();
    if (resendAt > Date.now()) return;
    await run(async () => {
      const { error } = await sendSignInEmail(address);
      if (error) throw error;
      if (mounted.current) { setSentTo(address); setResendAt(Date.now() + 60000); }
    });
  }
  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (sentTo) {
      void run(async () => {
        const { data, error } = await authClient.auth.verifyOtp({ email: sentTo, token: code.trim(), type: "email" });
        if (error) throw error;
        if (!data.session) throw new Error("No verified session");
        if (mounted.current) onContinue();
      });
    } else if (linkMode) void sendLink();
    else void run(async () => {
      const { data, error } = await authClient.auth.signInWithPassword({ email: email.trim(), password });
      if (error) throw error;
      if (!data.session) throw new Error("No verified session");
      if (mounted.current) { setPassword(""); onContinue(); }
    });
  }
  return <>
    {!embedded && <SignInVideo />}
    <section className={`sign-in-screen${linkMode ? " email-entry-screen" : ""}`} aria-labelledby="sign-in-title">
      <button className="sign-in-back" disabled={busy} onClick={() => {
        if (sentTo) { setSentTo(""); setCode(""); setShowCode(false); setError(""); }
        else onBack();
      }}><ArrowLeft size={20} aria-hidden="true" />{t("Back", "返回")}</button>
      <header className="sign-in-heading"><h1 id="sign-in-title" tabIndex={-1}>{sentTo ? t("Check your email", "查看你的電郵", "查看你的邮箱") : linkMode ? t("Enter your email", "輸入你嘅電郵") : t("Welcome back", "歡迎返嚟")}</h1></header>
      {sentTo && <div className="sign-in-delivery" role="status">
        <p>{t("Open the sign-in link sent to", "請開啟發送至以下地址的登入連結：", "请打开已发送至以下地址的登录链接：")} <strong>{sentTo}</strong></p>
        <p>{t("Check your spam folder too. If the email contains a code, you can enter it below.", "也請查看垃圾郵件。如電郵附有驗證碼，可在下方輸入。", "也请检查垃圾邮件。如果邮件附有验证码，可在下方输入。")}</p>
      </div>}
      {(!sentTo || showCode) && <form onSubmit={submit} aria-busy={busy}>
        {!sentTo ? <>
          <label className="sr-only" htmlFor="sign-in-email">{t("Email", "電郵")}</label>
          <div className="sign-in-field"><Mail className="sign-in-field-icon" size={20} aria-hidden="true" /><input id="sign-in-email" name="email" type="email" autoComplete="email" inputMode="email" autoCapitalize="none" spellCheck={false} placeholder="you@example.com" required disabled={busy} value={email} onChange={event => setEmail(event.target.value)} /></div>
          {!linkMode && <>
            <label className="sr-only" htmlFor="sign-in-password">{t("Password", "密碼")}</label>
            <div className="sign-in-password sign-in-field"><LockKeyhole className="sign-in-field-icon" size={20} aria-hidden="true" /><input id="sign-in-password" name="password" type={visible ? "text" : "password"} placeholder={t("Your password", "你嘅密碼")} autoComplete="current-password" required disabled={busy} value={password} onChange={event => setPassword(event.target.value)} />
              <button type="button" aria-label={t(visible ? "Hide password" : "Show password", visible ? "隱藏密碼" : "顯示密碼")} aria-pressed={visible} onClick={() => setVisible(!visible)}>{visible ? <EyeOff size={21} /> : <Eye size={21} />}</button>
            </div>
            <button className="sign-in-help" type="button" disabled={busy} onClick={() => { setLinkMode(true); setPassword(""); setError(""); }}>{t("Use an email sign-in link instead", "改用電郵登入連結", "改用邮件登录链接")}</button>
          </>}
        </> : <>
          <label htmlFor="sign-in-code">{t("Email code", "電郵驗證碼", "邮件验证码")}</label>
          <div className="sign-in-field"><Mail className="sign-in-field-icon" size={20} aria-hidden="true" /><input id="sign-in-code" name="code" inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6,10}" minLength={6} maxLength={10} placeholder="000000" required disabled={busy} value={code} onChange={event => setCode(event.target.value.replace(/\D/g, ""))} /></div>
        </>}
        <button className="primary full" type="submit" disabled={busy || (!sentTo && linkMode && remaining > 0)}>{busy ? t("Please wait…", "請稍候…") : sentTo ? t("Verify and sign in", "驗證並登入", "验证并登录") : linkMode && remaining > 0 ? t(`Try again in ${remaining}s`, `${remaining} 秒後可重試`, `${remaining} 秒后可重试`) : linkMode ? t("Continue", "繼續") : t("Sign in", "登入")}</button>
      </form>}
      {error && <p className="sign-in-status sign-in-error" role="alert">{error}</p>}
      {sentTo && !showCode && <button className="secondary full" onClick={() => setShowCode(true)}>{t("Enter an email code", "輸入電郵驗證碼", "输入邮件验证码")}</button>}
      {sentTo && <button className="sign-in-resend" disabled={busy || remaining > 0} onClick={() => void sendLink()}>{remaining > 0 ? t(`Resend in ${remaining}s`, `${remaining} 秒後可重新發送`, `${remaining} 秒后可重新发送`) : t("Resend email", "重新發送電郵", "重新发送邮件")}</button>}
    </section>
  </>;
}
