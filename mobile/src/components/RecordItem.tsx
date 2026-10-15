import { ChevronRight, Link2 } from "lucide-react";
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
        <time>
          <strong>
            {date.toLocaleTimeString(zh ? "zh-HK" : "en-HK", {
              hour: "2-digit",
              minute: "2-digit",
              hour12: false,
            })}
          </strong>
          <small>
            {date.toLocaleDateString(zh ? "zh-HK" : "en-HK", {
              month: "short",
              day: "numeric",
            })}
          </small>
        </time>
        <div className="record-body">
          <p>{record.text}</p>
          <div className="record-tags">
            <span className={`record-tag tag-${record.category}`}>
              {categories[record.category][zh ? 1 : 0]}
            </span>
            {record.location && <span>{record.location}</span>}
            {record.durationMinutes !== null && (
              <span>
                {record.durationMinutes} {t("min", "分鐘")}
              </span>
            )}
          </div>
        </div>
        <ChevronRight size={16} />
      </button>
      {related.length > 0 && (
        <div className="related-records">
          <h3>
            <Link2 size={13} />
            {t(
              "Related past records · same category",
              "關聯的過往記錄 · 相同分類",
            )}
          </h3>
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
        </div>
      )}
    </article>
  );
}
