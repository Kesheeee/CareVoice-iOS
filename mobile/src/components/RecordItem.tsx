import { translator, languageLocale } from "../i18n";
import { ChevronRight, Clock3, Link2, MapPin } from "lucide-react";
import {
  categories,
  relatedRecords,
  type Language,
  type Observation,
} from "../domain";
export function RecordItem({
  record,
  records,
  language,
  onOpen,
}: {
  record: Observation;
  records: Observation[];
  language: Language;
  onOpen: (r: Observation) => void;
}) {
  const t = translator(language),
    related = relatedRecords(records, record),
    date = new Date(record.date);
  return (
    <article className="record-entry">
      <button className="record-main" onClick={() => onOpen({ ...record })}>
        <span className="record-topline">
          <span className={`record-tag tag-${record.category}`}>
            {t(...categories[record.category])}
          </span>
          <time>
            {date.toLocaleString(languageLocale(language), {
              month: "short",
              day: "numeric",
              hour: "2-digit",
              minute: "2-digit",
              hour12: false,
            })}
          </time>
        </span>
        <span className="record-note">{record.text}</span>
        <span className="record-view-link">{t("View details", "查看詳情")}<ChevronRight size={16} aria-hidden="true" /></span>
        {(record.location || record.durationMinutes !== null) && (
          <span className="record-footline">
            {record.location && (
              <span>
                <MapPin size={13} />
                {record.location}
              </span>
            )}
            {record.durationMinutes !== null && (
              <span>
                <Clock3 size={13} />
                {record.durationMinutes} {t("min", "分鐘")}
              </span>
            )}
          </span>
        )}
      </button>
      {related.length > 0 && (
        <details className="related-records">
          <summary role="button">
            <Link2 size={14} />
            <span>{t("Same category", "同一分類")}</span>
            <span className="related-count">{related.length}</span>
            <ChevronRight size={14} />
          </summary>
          <p className="related-basis">
            {t("Grouped by the same category", "顯示同一分類嘅記錄")}
          </p>
          {related.map((r) => (
            <button key={r.id} onClick={() => onOpen({ ...r })}>
              <time>
                {new Date(r.date).toLocaleDateString(languageLocale(language), {
                  month: "short",
                  day: "numeric",
                })}
              </time>
              <span>{r.text}</span>
            </button>
          ))}
        </details>
      )}
    </article>
  );
}
