import { translator } from "../i18n";
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
}: {
  records: Observation[];
  language: Language;
  search: string;
  filter: Category | "all";
  onSearch: (value: string) => void;
  onFilter: (value: Category | "all") => void;
  onReport: () => void;
  onOpen: (record: Observation) => void;
}) {
  const t = translator(language);
  const visible = records
    .filter(
      (r) =>
        (filter === "all" || r.category === filter) &&
        `${r.text} ${r.location} ${r.context} ${r.helped}`
          .toLowerCase()
          .includes(search.toLowerCase()),
    )
    .sort((a, b) => b.date.localeCompare(a.date));
  return (
    <section className="records-screen">
      <div className="records-heading">
        <h1>{t("Records", "記錄")}</h1>
        <button className="records-report-button" onClick={onReport}>
          <FileText size={18} aria-hidden="true" />{t("Reports", "報告")}
        </button>
      </div>
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
            {records.length
              ? t("No matching observations", "搵唔到相符嘅觀察")
              : t("No records yet", "仲未有記錄")}
          </h2>
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
