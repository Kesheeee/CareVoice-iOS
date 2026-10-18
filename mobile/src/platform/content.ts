// Client-side copy of Harmon's curated content, bundled under public/data/.
// Lets content browsing work without the backend (the /ask endpoint still
// needs the backend for the DeepSeek call).

export type CitableAssertion = {
  assertion_id: string; topic: string; quote: string; plain_tc: string;
  locator?: string; org: string; title_tc: string; url: string; captured_on: string;
  source_status: string; plain_en?: string; quote_en?: string; title_en?: string; org_en?: string;
};
export type ServiceType = {
  code: string; alias_tc?: string; alias_en?: string; name_tc: string; name_en?: string;
  target_tc?: string; target_en?: string; referral_tc?: string; fee_tc?: string;
  wait_note_tc?: string; wait_note_en?: string; notes_tc?: string;
};
export type ServiceUnit = {
  unit_id: string; name_tc: string; name_en?: string; service_code?: string;
  district?: string; district_en?: string; address?: string; phone?: string;
};
export type GlossaryTerm = {
  term: string; term_en?: string; full_tc: string; full_en?: string; plain_tc: string; plain_en?: string;
};
export type RedFlag = {
  flag_id: string; signal_tc: string; signal_en?: string; route_tc: string; route_en?: string;
  route_contact?: string; route_contact_en?: string; never_say_tc: string;
};

export type BundledContent = {
  citableAssertions: CitableAssertion[];
  serviceTypes: ServiceType[];
  serviceUnits: ServiceUnit[];
  glossary: GlossaryTerm[];
  pathwaySteps: unknown[];
  checklistItems: unknown[];
  redFlags: RedFlag[];
  manifest: Record<string, unknown> | null;
};

const BASE = "/data";

async function fetchJson<T>(name: string): Promise<T | null> {
  try {
    const res = await fetch(`${BASE}/${name}`);
    return res.ok ? ((await res.json()) as T) : null;
  } catch {
    return null;
  }
}

export async function loadContent(): Promise<BundledContent> {
  const [citableAssertions, serviceTypes, serviceUnits, glossary, pathwaySteps, checklistItems, redFlags, manifest] =
    await Promise.all([
      fetchJson<CitableAssertion[]>("citable_assertions.json"),
      fetchJson<ServiceType[]>("service_types.json"),
      fetchJson<ServiceUnit[]>("service_units.json"),
      fetchJson<GlossaryTerm[]>("glossary.json"),
      fetchJson<unknown[]>("pathway_steps.json"),
      fetchJson<unknown[]>("checklist_items.json"),
      fetchJson<RedFlag[]>("red_flags.json"),
      fetchJson<Record<string, unknown>>("manifest.json"),
    ]);
  return {
    citableAssertions: citableAssertions ?? [],
    serviceTypes: serviceTypes ?? [],
    serviceUnits: serviceUnits ?? [],
    glossary: glossary ?? [],
    pathwaySteps: pathwaySteps ?? [],
    checklistItems: checklistItems ?? [],
    redFlags: redFlags ?? [],
    manifest,
  };
}
