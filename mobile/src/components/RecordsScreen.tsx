import { recordStreak } from "../streak";
import { useState } from "react";
import { translator, languageLocale } from "../i18n";
import { ChevronLeft, ChevronRight, Plus } from "lucide-react";
import {
  BookOpen,
  FileText,
  Search,
  X,
} from "lucide-react";
import {
  categories,
  type Category,
  type Language,
  type Observation,
} from "../domain";
import { RecordItem } from "./RecordItem";
export function RecordsScreen({
  records,
  language,
  search,
  filter,
  onSearch,
  onFilter,
  onReport,
  onOpen,
  selectedDate,
  onDate,
  onAdd,
}: {
  records: Observation[];
  language: Language;
  search: string;
  filter: Category | "all";
  onSearch: (value: string) => void;
  onFilter: (value: Category | "all") => void;
  onReport: () => void;
  onOpen: (record: Observation) => void;
  selectedDate: Date;
  onDate: (date: Date) => void;
  onAdd: () => void;
}) {
  const t = translator(language);
  const [month, setMonth] = useState(() => new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1));
  const [allDates, setAllDates] = useState(false);
  const dayKey = (date: Date) => `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
  const today = new Date();
  const streak = recordStreak(records, today);
  const offset = (month.getDay() + 6) % 7;
  const days = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
  const cells = Math.ceil((offset + days) / 7) * 7;
  const locale = languageLocale(language);
  const visible = records
    .filter(
      (r) =>
        (allDates || dayKey(new Date(r.date)) === dayKey(selectedDate)) &&
        (filter === "all" || r.category === filter) &&
        `${r.text} ${r.location} ${r.context} ${r.helped}`
          .toLowerCase()
          .includes(search.toLowerCase()),
    )
    .sort((a, b) => b.date.localeCompare(a.date));
  return (
    <section className="records-screen">
      <div className="records-heading">
        <h1>{t("Tracker", "追蹤")}</h1>
        <div className="tracker-header-actions">
        <button className="records-report-button" onClick={onReport}>
          <FileText size={18} aria-hidden="true" />{t("Reports", "報告")}
        </button>
        <span className="tracker-streak" role="status" aria-label={t(`${streak} day recording streak`, `連續記錄 ${streak} 天`)} title={t("Consecutive days with records. Log today to keep it going.", "連續有記錄的天數，今天記錄即可延續。") }><span aria-hidden="true">🔥</span><strong>{streak}</strong></span>
        </div>
      </div>
      <div className="tracker-calendar">
        <div className="tracker-month">
          <button aria-label={t("Previous month", "上一個月")} onClick={() => setMonth(new Date(month.getFullYear(), month.getMonth() - 1, 1))}><ChevronLeft /></button>
          <h2>{month.toLocaleDateString(locale, { month: "long", year: "numeric" })}</h2>
          <button aria-label={t("Next month", "下一個月")} onClick={() => setMonth(new Date(month.getFullYear(), month.getMonth() + 1, 1))}><ChevronRight /></button>
        </div>
        <div className="tracker-grid">
          {Array.from({length: 7}, (_, i) => <span className="tracker-weekday" key={i}>{new Date(2026, 0, 5 + i).toLocaleDateString(locale, {weekday: "short"})}</span>)}
          {Array.from({length: cells}, (_, i) => {
            const date = new Date(month.getFullYear(), month.getMonth(), i - offset + 1);
            const count = records.filter(r => dayKey(new Date(r.date)) === dayKey(date)).length;
            const active = !allDates && dayKey(date) === dayKey(selectedDate);
            return <button key={i} className={`tracker-day ${date.getMonth() !== month.getMonth() ? "outside" : ""}`} aria-pressed={active} aria-current={dayKey(date) === dayKey(today) ? "date" : undefined} aria-label={`${date.toLocaleDateString(locale, {dateStyle: "full"})}, ${count} ${t("records", "則記錄")}`} onClick={() => {onDate(date);setAllDates(false);}}>
              <span>{date.getDate()}</span><span className="tracker-dot" aria-hidden="true">{count > 0 ? "•" : ""}</span>
            </button>;
          })}
        </div>
        <div className="tracker-calendar-footer"><span>{t("A dot means a recorded day", "圓點表示當天有記錄")}</span><button onClick={() => {onDate(today);setMonth(new Date(today.getFullYear(), today.getMonth(), 1));setAllDates(false);}}>{t("Today", "今天")}</button></div>
      </div>
      <div className="tracker-day-heading"><h2>{allDates ? t("All records", "全部記錄") : selectedDate.toLocaleDateString(locale, {month: "short", day: "numeric"})}</h2><button className="records-report-button" disabled={selectedDate > today && dayKey(selectedDate) !== dayKey(today)} onClick={onAdd}><Plus size={18}/>{t("Add record", "新增記錄")}</button></div>
      <button className="tracker-view-toggle" onClick={() => setAllDates(!allDates)}>{allDates ? t("Show selected day", "顯示所選日期") : t("Browse all records", "瀏覽全部記錄")}</button>
      <div className="records-search">
        <Search size={19} />
        <input
          aria-label={t("Search observations", "搜尋觀察")}
          placeholder={t("Search records", "搜尋記錄")}
          value={search}
          onChange={(e) => onSearch(e.target.value)}
        />
        {search && (
          <button
            aria-label={t("Clear search", "清除搜尋")}
            onClick={() => onSearch("")}
          >
            <X size={17} />
          </button>
        )}
      </div>
      <div
        className="record-filters"
        role="group"
        aria-label={t("Filter category", "篩選分類")}
      >
        <button aria-pressed={filter === "all"} onClick={() => onFilter("all")}>
          {t("All", "全部")}
        </button>
        {Object.entries(categories).map(([value, label]) => (
          <button
            key={value}
            aria-pressed={filter === value}
            onClick={() => onFilter(value as Category)}
          >
            {t(...label)}
          </button>
        ))}
      </div>
      {visible.length ? (
        <div className="records-list">
          {visible.map((r) => (
            <RecordItem
              key={r.id}
              record={r}
              records={records}
              language={language}
              onOpen={onOpen}
            />
          ))}
        </div>
      ) : (
        <div className="records-empty">
          {records.length ? <Search size={29} /> : <BookOpen size={29} />}
          <h2>
            {!allDates && !search && filter === "all" ? t("No records for this day", "當天尚未有記錄") : records.length
              ? t("No matching observations", "搵唔到相符嘅觀察")
              : t("No records yet", "仲未有記錄")}
          </h2>
          {!allDates && <p>{t("Choose Add record to capture this day.", "點按新增記錄，記下這一天。")}</p>}
          {records.length > 0 && (
            <button
              onClick={() => {
                onSearch("");
                onFilter("all");
              }}
            >
              {t("Clear filters", "清除篩選")}
            </button>
          )}
        </div>
      )}
    </section>
  );
}
