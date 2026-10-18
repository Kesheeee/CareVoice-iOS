import { translator } from "../i18n";
import { useRef } from "react";
import {
  BookOpen,
  FileText,
  MoreHorizontal,
  Plus,
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
  onVoice,
  onReport,
  onEdit,
}: {
  records: Observation[];
  language: Language;
  search: string;
  filter: Category | "all";
  onSearch: (value: string) => void;
  onFilter: (value: Category | "all") => void;
  onVoice: () => void;
  onReport: () => void;
  onEdit: (record: Observation) => void;
}) {
  const t = translator(language),
    menu = useRef<HTMLDetailsElement>(null);
  const visible = records
    .filter(
      (r) =>
        (filter === "all" || r.category === filter) &&
        `${r.text} ${r.location} ${r.context} ${r.helped}`
          .toLowerCase()
          .includes(search.toLowerCase()),
    )
    .sort((a, b) => b.date.localeCompare(a.date));
  const action = (fn: () => void) => {
    if (menu.current) menu.current.open = false;
    fn();
  };
  return (
    <section className="records-screen">
      <div className="records-heading">
        <h1>{t("Records", "記錄")}</h1>
        <div className="records-heading-actions">
          <details
            className="records-options"
            ref={menu}
            onBlur={(e) => {
              if (!e.currentTarget.contains(e.relatedTarget))
                e.currentTarget.open = false;
            }}
            onKeyDown={(e) => {
              if (e.key === "Escape") {
                e.currentTarget.open = false;
                e.currentTarget.querySelector("summary")?.focus();
              }
            }}
          >
            <summary
              role="button"
              aria-label={t("More record actions", "更多記錄操作")}
            >
              <MoreHorizontal size={22} />
            </summary>
            <div className="records-menu">
              <button onClick={() => action(onReport)}>
                <FileText size={18} />
                {t("Prepare a report", "準備報告")}
              </button>
            </div>
          </details>
        </div>
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
              onEdit={onEdit}
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
      <button
        type="button"
        className="records-add"
        aria-label={t("Add a record", "新增記錄")}
        aria-haspopup="dialog"
        onClick={() => action(onVoice)}
      >
        <Plus size={26} aria-hidden="true" />
      </button>
    </section>
  );
}
