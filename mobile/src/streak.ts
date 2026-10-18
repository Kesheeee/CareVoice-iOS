// Count local calendar days, allowing today to remain unlogged until midnight.
export function recordStreak(records: { date: string }[], now = new Date()): number {
  const key = (d: Date) => `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
  const days = new Set(records.map(r => new Date(r.date)).filter(d => !Number.isNaN(d.getTime())).map(key));
  const cursor = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12);
  if (!days.has(key(cursor))) cursor.setDate(cursor.getDate() - 1);
  let count = 0;
  while (days.has(key(cursor))) {
    count++;
    cursor.setDate(cursor.getDate() - 1);
  }
  return count;
}
