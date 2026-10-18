import { useEffect, useRef, useState, type FormEvent } from "react";
import { authClient, authErrorMessage } from "../platform/auth";
import { translator } from "../i18n";
import type { Language } from "../domain";
import "../sign-in.css";

export function PasswordUpdate({
  language,
  onDone,
}: {
  language: Language;
  onDone: () => void;
}) {
  const t = translator(language);
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const title = useRef<HTMLHeadingElement>(null);
  const inFlight = useRef(false);
  useEffect(() => {
    title.current?.focus();
  }, []);
  async function submit(event: FormEvent) {
    event.preventDefault();
    if (inFlight.current) return;
    if (password !== confirmation) {
      setError(
        t(
          "Your passwords don’t match.",
          "兩次輸入的密碼不一致。",
          "两次输入的密码不一致。",
        ),
      );
      return;
    }
    inFlight.current = true;
    setBusy(true);
    setError("");
    try {
      const { error } = await authClient.auth.updateUser({ password });
      if (error) throw error;
      setPassword("");
      setConfirmation("");
      onDone();
    } catch (cause) {
      setError(authErrorMessage(cause, language));
    } finally {
      inFlight.current = false;
      setBusy(false);
    }
  }
  return (
    <main className="password-update sign-in-screen">
      <header className="sign-in-heading">
        <h1 ref={title} tabIndex={-1}>
          {t("Choose a new password", "設定新密碼", "设置新密码")}
        </h1>
      </header>
      <form onSubmit={submit} aria-busy={busy}>
        <label htmlFor="new-password">
          {t("New password", "新密碼", "新密码")}
        </label>
        <div className="sign-in-field">
          <input
            id="new-password"
            type="password"
            autoComplete="new-password"
            required
            minLength={8}
            placeholder={t(
              "At least 8 characters",
              "最少 8 個字元",
              "至少 8 个字符",
            )}
            value={password}
            disabled={busy}
            onChange={(event) => setPassword(event.target.value)}
          />
        </div>
        <label htmlFor="confirm-new-password">
          {t("Confirm password", "確認密碼", "确认密码")}
        </label>
        <div className="sign-in-field">
          <input
            id="confirm-new-password"
            type="password"
            autoComplete="new-password"
            required
            minLength={8}
            value={confirmation}
            disabled={busy}
            onChange={(event) => setConfirmation(event.target.value)}
          />
        </div>
        {error && (
          <p className="sign-in-status sign-in-error" role="alert">
            {error}
          </p>
        )}
        <button className="primary full" disabled={busy}>
          {busy
            ? t("Saving…", "儲存中…", "保存中…")
            : t(
                "Save password and continue",
                "儲存密碼並繼續",
                "保存密码并继续",
              )}
        </button>
      </form>
    </main>
  );
}
