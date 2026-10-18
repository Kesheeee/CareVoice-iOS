// Hallmark · pre-emit critique: P5 H5 E4 S5 R5 V4
// Existing CareVoice tokens; reading first, explicit editing and report actions.
import { ArrowLeft, ChevronRight, Clock3, FileText, MapPin, Pencil, Trash2 } from "lucide-react";
import { categories, relatedRecords, type Language, type Observation } from "../domain";
import { languageLocale, translator } from "../i18n";

export function RecordDetails({ record, records, language, saved, onBack, onEdit, onAddDetails, onOpen, onReport, onDelete }: {
  record: Observation; records: Observation[]; language: Language;
  saved: boolean;
  onBack: () => void; onEdit: () => void; onOpen: (record: Observation) => void;
  onAddDetails: () => void;
  onReport: () => void; onDelete: () => void;
}) {
  const t = translator(language);
  const related = relatedRecords(records, record);
  const date = (value: string) => new Date(value).toLocaleString(languageLocale(language), {
    year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit", hour12: false,
  });
  return <section className="record-details" aria-labelledby="record-details-title">
    <div className="record-detail-nav">
      <button onClick={onBack}><ArrowLeft size={20} aria-hidden="true" />{t("Records", "記錄")}</button>
      <button onClick={onEdit}><Pencil size={17} aria-hidden="true" />{t("Edit", "編輯")}</button>
    </div>
    <h1 id="record-details-title">{t("Record details", "記錄詳情")}</h1>
    {saved && <p className="record-detail-saved" role="status">{t("Record saved", "記錄已儲存")}</p>}
    <article className="record-detail-body">
      <span className={`record-tag tag-${record.category}`}>{t(...categories[record.category])}</span>
      <time dateTime={record.date}>{date(record.date)}</time>
      <h2>{t("What happened", "發生了甚麼")}</h2>
      <p className="record-detail-note">{record.text}</p>
      {(record.location || record.durationMinutes !== null) && <div className="record-detail-meta">
        {record.location && <span><MapPin size={17} aria-hidden="true" />{record.location}</span>}
        {record.durationMinutes !== null && <span><Clock3 size={17} aria-hidden="true" />{record.durationMinutes} {t("minutes", "分鐘")}</span>}
      </div>}
      {record.context && <div className="record-detail-context"><h2>{t("What happened before", "之前發生了甚麼")}</h2><p>{record.context}</p></div>}
      {record.helped && <div className="record-detail-context"><h2>{t("What helped", "有幫助的方法")}</h2><p>{record.helped}</p></div>}
    </article>
    {(!record.context || !record.helped) && <aside className="record-detail-prompt">
      <h2>{t("Remember a little more?", "還記得更多細節嗎？")}</h2>
      <p>{t("Add what happened before or what helped, while it’s still fresh.", "趁記憶還清晰，補充之前發生的事或有幫助的方法。")}</p>
      <button onClick={onAddDetails}><Pencil size={16} aria-hidden="true" />{t("Add details", "補充詳情")}</button>
    </aside>}
    <section className="record-detail-related" aria-labelledby="same-category-title">
      <h2 id="same-category-title">{t("Earlier records in this category", "同類別的過往記錄")}</h2>
      <p>{t("Grouped by the category you chose.", "按你選擇的類別分組。")}</p>
      {related.length ? <div className="record-detail-related-list">{related.map(r => <button key={r.id} onClick={() => onOpen(r)}>
        <span><time dateTime={r.date}>{date(r.date)}</time><span>{r.text}</span></span>
        <ChevronRight size={18} aria-hidden="true" />
      </button>)}</div> : <p className="record-detail-empty">{t("No earlier records in this category yet.", "這個類別暫時沒有更早的記錄。")}</p>}
    </section>
    <button className="secondary full record-detail-report" onClick={onReport}><FileText size={19} aria-hidden="true" />{t("Prepare a report", "準備報告")}</button>
    <button className="danger-button record-detail-delete" onClick={onDelete}><Trash2 size={16} aria-hidden="true" />{t("Delete record", "刪除記錄")}</button>
  </section>;
}
