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
  onEdit,
}: {
  record: Observation;
  records: Observation[];
  language: Language;
  onEdit: (r: Observation) => void;
}) {
  const zh = language === "zh",
    t = (en: string, tc: string) => (zh ? tc : en),
    related = relatedRecords(records, record),
    date = new Date(record.date);
  return (
    <article className="record-entry">
      <button className="record-main" onClick={() => onEdit({ ...record })}>
        <span className="record-topline">
          <span className={`record-tag tag-${record.category}`}>
            {categories[record.category][zh ? 1 : 0]}
          </span>
          <time>
            {date.toLocaleString(zh ? "zh-HK" : "en-HK", {
              month: "short",
              day: "numeric",
              hour: "2-digit",
              minute: "2-digit",
              hour12: false,
            })}
          </time>
        </span>
        <span className="record-note">{record.text}</span>
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
            <span>{t("Related records", "關聯記錄")}</span>
            <span className="related-count">{related.length}</span>
            <ChevronRight size={14} />
          </summary>
          <p className="related-basis">
            {t("Grouped by the same category", "按相同分類顯示")}
          </p>
          {related.map((r) => (
            <button key={r.id} onClick={() => onEdit({ ...r })}>
              <time>
                {new Date(r.date).toLocaleDateString(zh ? "zh-HK" : "en-HK", {
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
