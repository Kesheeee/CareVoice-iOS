import { translator } from "../i18n";
import { useEffect, useRef, useState, type FormEvent } from "react";
import { ArrowLeft, Eye, EyeOff, Mail, LockKeyhole } from "lucide-react";
import { SignInVideo } from "./SignInVideo";
import { authClient, authErrorMessage } from "../platform/auth";
import type { Language } from "../domain";
import "../sign-in.css";

export function SignIn({
  language,
  onBack,
  onContinue,
  embedded = false,
  createAccount = false,
}: {
  createAccount?: boolean;
  embedded?: boolean;
  language: Language;
  onBack: () => void;
  onContinue: () => void;
}) {
  const t = translator(language);
  const [creating, setCreating] = useState(createAccount);
  const [recovering, setRecovering] = useState(false);
  const [visible, setVisible] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [repeatPassword, setRepeatPassword] = useState("");
  const [confirmation, setConfirmation] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const title = useRef<HTMLHeadingElement>(null);
  const mounted = useRef(true);
  const requestInFlight = useRef(false);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  useEffect(() => {
    title.current?.focus({ preventScroll: true });
  }, [creating, confirmation, recovering]);
  function changeMode() {
    setCreating(recovering ? false : !creating);
    setRecovering(false);
    setConfirmation(false);
    setError("");
    setPassword("");
    setRepeatPassword("");
    setVisible(false);
  }
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (requestInFlight.current) return;
    setError("");
    if (creating && password !== repeatPassword) {
      setError(
        t(
          "Your passwords don’t match.",
          "兩次輸入的密碼不一致。",
          "两次输入的密码不一致。",
        ),
      );
      return;
    }
    requestInFlight.current = true;
    setBusy(true);
    try {
      if (recovering) {
        const { error } = await authClient.auth.resetPasswordForEmail(
          email.trim(),
          { redirectTo: `${window.location.origin}/` },
        );
        if (error) throw error;
        if (mounted.current) setConfirmation(true);
        return;
      }
      const credentials = { email: email.trim(), password };
      const { data, error } = creating
        ? await authClient.auth.signUp({
            ...credentials,
            options: { emailRedirectTo: `${window.location.origin}/` },
          })
        : await authClient.auth.signInWithPassword(credentials);
      if (error) throw error;
      if (!mounted.current) return;
      if (!data.session && (!creating || !data.user))
        throw new Error("No account response");
      setPassword("");
      setRepeatPassword("");
      setVisible(false);
      if (data.session) onContinue();
      else setConfirmation(true);
    } catch (cause) {
      if (mounted.current) setError(authErrorMessage(cause, language));
    } finally {
      requestInFlight.current = false;
      if (mounted.current) setBusy(false);
    }
  }
  return (
    <>
      {!embedded && <SignInVideo />}
      <section
        className={`sign-in-screen${creating ? " create-account-screen" : ""}`}
        aria-labelledby="sign-in-title"
      >
        <button className="sign-in-back" disabled={busy} onClick={onBack}>
          <ArrowLeft size={20} aria-hidden="true" />
          {t("Back", "返回")}
        </button>
        <header className="sign-in-heading">
          <h1 id="sign-in-title" ref={title} tabIndex={-1}>
            {confirmation
              ? t("Check your email", "驗證你的電郵", "验证你的邮箱")
              : recovering
                ? t("Reset your password", "重設密碼", "重置密码")
                : creating
                  ? t("Create your account", "建立你的帳戶", "创建你的账户")
                  : t("Welcome back", "歡迎返嚟")}
          </h1>
        </header>
        {confirmation ? (
          <>
            <div className="sign-in-delivery" role="status">
              <p>
                {recovering
                  ? t(
                      "If an account exists, check your inbox for a password reset link for",
                      "如已有帳戶，請查看以下電郵的密碼重設連結：",
                      "如已有账户，请检查以下邮箱的密码重置链接：",
                    )
                  : t(
                      "Check your inbox for a confirmation link for",
                      "請查看以下電郵的收件匣以取得確認連結：",
                      "请检查以下邮箱的收件箱以获取确认链接：",
                    )}{" "}
                <strong>{email.trim()}</strong>
              </p>
              <p>
                {recovering
                  ? t(
                      "Open the link to choose a new password. Check your spam folder too.",
                      "請開啟連結設定新密碼，也請查看垃圾郵件。",
                      "请打开链接设置新密码，也请检查垃圾邮件。",
                    )
                  : t(
                      "Confirm your email before signing in with your password. If you already have an account, sign in instead.",
                      "確認電郵後，即可使用密碼登入。如已有帳戶，請直接登入。",
                      "验证邮箱后，即可使用密码登录。如已有账户，请直接登录。",
                    )}
              </p>
            </div>
            <button className="primary full" onClick={changeMode}>
              {t("Back to sign in", "返回登入", "返回登录")}
            </button>
          </>
        ) : (
          <form onSubmit={submit} aria-busy={busy}>
            <label htmlFor="sign-in-email">{t("Email", "電郵")}</label>
            <div className="sign-in-field">
              <Mail
                className="sign-in-field-icon"
                size={20}
                aria-hidden="true"
              />
              <input
                id="sign-in-email"
                name="email"
                type="email"
                autoComplete="email"
                inputMode="email"
                autoCapitalize="none"
                spellCheck={false}
                placeholder="you@example.com"
                required
                disabled={busy}
                value={email}
                onChange={(event) => setEmail(event.target.value)}
              />
            </div>
            {!recovering && (
              <>
                <label htmlFor="sign-in-password">
                  {t("Password", "密碼")}
                </label>
                <div className="sign-in-password sign-in-field">
                  <LockKeyhole
                    className="sign-in-field-icon"
                    size={20}
                    aria-hidden="true"
                  />
                  <input
                    id="sign-in-password"
                    name="password"
                    type={visible ? "text" : "password"}
                    placeholder={
                      creating
                        ? t(
                            "At least 8 characters",
                            "最少 8 個字元",
                            "至少 8 个字符",
                          )
                        : t("Your password", "你的密碼", "你的密码")
                    }
                    autoComplete={
                      creating ? "new-password" : "current-password"
                    }
                    minLength={creating ? 8 : undefined}
                    aria-describedby={creating ? "password-hint" : undefined}
                    required
                    disabled={busy}
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                  />
                  <button
                    type="button"
                    disabled={busy}
                    aria-label={t(
                      visible ? "Hide password" : "Show password",
                      visible ? "隱藏密碼" : "顯示密碼",
                    )}
                    aria-pressed={visible}
                    onClick={() => setVisible(!visible)}
                  >
                    {visible ? <EyeOff size={21} /> : <Eye size={21} />}
                  </button>
                </div>
                {creating && (
                  <>
                    <p className="password-hint" id="password-hint">
                      {t(
                        "Use at least 8 characters.",
                        "請使用最少 8 個字元。",
                        "请使用至少 8 个字符。",
                      )}
                    </p>
                    <label htmlFor="sign-in-repeat-password">
                      {t("Confirm password", "確認密碼", "确认密码")}
                    </label>
                    <div className="sign-in-field">
                      <LockKeyhole
                        className="sign-in-field-icon"
                        size={20}
                        aria-hidden="true"
                      />
                      <input
                        id="sign-in-repeat-password"
                        name="confirmPassword"
                        type={visible ? "text" : "password"}
                        autoComplete="new-password"
                        placeholder={t(
                          "Enter your password again",
                          "再次輸入密碼",
                          "再次输入密码",
                        )}
                        required
                        minLength={8}
                        disabled={busy}
                        value={repeatPassword}
                        onChange={(event) =>
                          setRepeatPassword(event.target.value)
                        }
                      />
                    </div>
                  </>
                )}
              </>
            )}
            {!creating && !recovering && (
              <button
                className="sign-in-help"
                type="button"
                disabled={busy}
                onClick={() => {
                  setRecovering(true);
                  setPassword("");
                  setVisible(false);
                  setError("");
                }}
              >
                {t("Set or reset password", "設定或重設密碼", "设置或重置密码")}
              </button>
            )}
            {error && (
              <p className="sign-in-status sign-in-error" role="alert">
                {error}
              </p>
            )}
            <button className="primary full" type="submit" disabled={busy}>
              {busy
                ? t("Please wait…", "請稍候…")
                : recovering
                  ? t("Send reset email", "發送重設電郵", "发送重置邮件")
                  : creating
                    ? t("Create account", "建立帳戶", "创建账户")
                    : t("Sign in", "登入")}
            </button>
            <button
              className="sign-in-switch"
              type="button"
              disabled={busy}
              onClick={changeMode}
            >
              {recovering
                ? t("Back to sign in", "返回登入", "返回登录")
                : creating
                  ? t("I already have an account", "我已經有帳戶")
                  : t("Create an account", "建立新帳戶", "创建新账户")}
            </button>
          </form>
        )}
      </section>
    </>
  );
}
