import { createClient } from "@supabase/supabase-js";
import type { Language } from "../domain";
import { translator } from "../i18n";

export const hasAuthLinkError = new URLSearchParams(window.location.hash.slice(1)).has("error");
// Public client key only. Service-role credentials must never enter this bundle.
export const authClient = createClient(
  "https://lbbpuwtwhiectsmhhuej.supabase.co",
  "sb_publishable_uUt_7SQgMfPA0idY7ZBVHw_KOcWZHRY",
  { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, flowType: "implicit" } },
);

export async function sendSignInEmail(email: string) {
  return authClient.auth.signInWithOtp({
    email: email.trim(),
    options: { shouldCreateUser: true, emailRedirectTo: `${window.location.origin}/` },
  });
}

export function authErrorMessage(error: unknown, language: Language): string {
  const t = translator(language);
  const code = (error as { code?: string })?.code;
  const status = (error as { status?: number })?.status;
  if (code === "over_email_send_rate_limit" || code === "over_request_rate_limit" || status === 429)
    return t("Too many requests. Please wait a few minutes before trying again.", "請求次數過多，請等幾分鐘後再試。", "请求次数过多，请等几分钟后重试。");
  if (code === "email_address_not_authorized" || code === "email_address_not_allowed")
    return t("Email delivery is not set up for this address yet. Please contact CareVoice support.", "目前未能向此地址發送登入電郵，請聯絡 CareVoice 支援。", "目前无法向此地址发送登录邮件，请联系 CareVoice 支持。");
  if (code === "invalid_credentials")
    return t("The email or password is incorrect. Try again, or use an email sign-in link.", "電郵或密碼不正確。請再試一次，或使用電郵登入連結。", "邮箱或密码不正确。请重试，或使用邮件登录链接。");
  if (code === "email_not_confirmed")
    return t("Please confirm your email first, or request a sign-in link below.", "請先確認你的電郵，或在下方索取登入連結。", "请先验证邮箱，或在下方获取登录链接。");
  if (code === "otp_expired")
    return t("This sign-in code has expired or is incorrect. Request a new email and try again.", "登入驗證碼已過期或不正確。請重新索取電郵。", "登录验证码已过期或不正确，请重新获取邮件。");
  return t("We couldn’t sign you in. Check your connection and try again.", "暫時無法登入。請檢查網絡連線後再試。", "暂时无法登录，请检查网络连接后重试。");
}
