import { answers } from "../domain";
import { translator } from "../i18n";

const simplified = translator("zh-Hans");
const reportHeadings = ["Questionnaire responses", "問卷回答", "Earlier questionnaire responses (original wording)", "舊版問卷回答（原有題目）", "Observations", "觀察記錄", "Questions for the appointment", "見面時想問嘅問題"];
const headings = new Set(reportHeadings.flatMap(label => [label, simplified(label, label)]));
const answerLabels = new Set(Object.values(answers).flatMap(([en, traditional]) => [en, traditional, simplified(en, traditional)]));

// Format the same report text used for sharing so preview and export stay aligned.
export function ReportPreview({ text }: { text: string }) {
  const [header, ...blocks] = text.split(/\n\n/);
  const [, title, date] = header.split("\n");
  return <article className="report-paper">
    <header className="report-document-head"><h2>{title}</h2><span>{date}</span></header>
    {blocks.filter(Boolean).map((block, index) => {
      const lines = block.split("\n");
      return <section className="report-block" key={index}>
        {lines.map((line, i) => headings.has(line)
          ? <h3 key={i}>{line}</h3>
          : /^_+$/.test(line)
            ? <div className="report-writing-line" key={i} aria-hidden="true" />
            : <p key={i} className={answerLabels.has(line) && i > 0 && /^\d+\./.test(lines[i - 1]) ? "report-answer" : ""}>{line}</p>)}
      </section>;
    })}
  </article>;
}
