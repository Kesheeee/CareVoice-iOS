// Match the character classes offered by Supabase's strongest password policy.
export function passwordRequirements(password: string) {
  return {
    length: [...password].length >= 8,
    uppercase: /[A-Z]/.test(password),
    lowercase: /[a-z]/.test(password),
    number: /[0-9]/.test(password),
    symbol: /[!-/:-@\[-`{-~]/.test(password),
  };
}

export function isValidNewPassword(password: string) {
  return Object.values(passwordRequirements(password)).every(Boolean);
}
