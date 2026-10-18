import { createClient } from "@supabase/supabase-js";
import type { Language } from "../domain";
import { translator } from "../i18n";

export const hasAuthLinkError = new URLSearchParams(
  window.location.hash.slice(1),
).has("error");
// Capture intent before the SDK consumes the callback URL. A verified session
// is still required before the password form can render.
export const hasPasswordRecoveryLink = new URLSearchParams(window.location.hash.slice(1)).get("type") === "recovery";
// Public client key only. Service-role credentials must never enter this bundle.
export const authClient = createClient(
  "https://lbbpuwtwhiectsmhhuej.supabase.co",
  "sb_publishable_uUt_7SQgMfPA0idY7ZBVHw_KOcWZHRY",
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      flowType: "implicit",
    },
  },
);

export function authErrorMessage(error: unknown, language: Language): string {
  const t = translator(language);
  const code = (error as { code?: string })?.code;
  const status = (error as { status?: number })?.status;
  if (
    code === "over_email_send_rate_limit" ||
    code === "over_request_rate_limit" ||
    status === 429
  )
    return t(
      "Too many requests. Please wait a few minutes before trying again.",
      "請求次數過多，請等幾分鐘後再試。",
      "请求次数过多，请等几分钟后重试。",
    );
  if (
    code === "email_address_not_authorized" ||
    code === "email_address_not_allowed"
  )
    return t(
      "Email delivery is not set up for this address yet. Please contact CareVoice support.",
      "目前未能向此地址發送登入電郵，請聯絡 CareVoice 支援。",
      "目前无法向此地址发送登录邮件，请联系 CareVoice 支持。",
    );
  if (code === "invalid_credentials")
    return t(
      "The email or password is incorrect. Please try again.",
      "電郵或密碼不正確，請再試一次。",
      "邮箱或密码不正确，请重试。",
    );
  if (code === "email_not_confirmed")
    return t(
      "Please open the confirmation link in your email before signing in.",
      "請先開啟電郵中的確認連結，再登入。",
      "请先打开邮件中的确认链接，再登录。",
    );
  if (code === "weak_password")
    return t(
      "Choose a stronger password with letters, numbers and symbols.",
      "請使用包含字母、數字及符號的較強密碼。",
      "请使用包含字母、数字及符号的更强密码。",
    );
  if (code === "user_already_exists" || code === "email_exists")
    return t(
      "An account already exists for this email. Please sign in.",
      "此電郵已有帳戶，請登入。",
      "此邮箱已有账户，请登录。",
    );
  if (code === "signup_disabled")
    return t(
      "New accounts are temporarily unavailable. Please try again later.",
      "暫時無法建立新帳戶，請稍後再試。",
      "暂时无法创建新账户，请稍后重试。",
    );
  if (code === "otp_expired")
    return t(
      "This sign-in code has expired or is incorrect. Request a new email and try again.",
      "登入驗證碼已過期或不正確。請重新索取電郵。",
      "登录验证码已过期或不正确，请重新获取邮件。",
    );
  return t(
    "We couldn’t sign you in. Check your connection and try again.",
    "暫時無法登入。請檢查網絡連線後再試。",
    "暂时无法登录，请检查网络连接后重试。",
  );
}
