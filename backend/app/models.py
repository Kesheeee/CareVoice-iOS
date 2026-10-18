from typing import Optional

from pydantic import BaseModel


class CitableAssertion(BaseModel):
    assertion_id: str
    topic: str
    quote: str
    plain_tc: str
    locator: Optional[str] = None
    org: str
    title_tc: str
    url: str
    captured_on: str
    source_status: str
    plain_en: Optional[str] = None
    quote_en: Optional[str] = None
    locator_en: Optional[str] = None
    org_en: Optional[str] = None
    title_en: Optional[str] = None


class ServiceType(BaseModel):
    code: str
    alias_tc: Optional[str] = None
    alias_en: Optional[str] = None
    name_tc: str
    name_en: Optional[str] = None
    age_min_m: Optional[int] = None
    age_max_m: Optional[int] = None
    intensity_tc: Optional[str] = None
    intensity_en: Optional[str] = None
    target_tc: Optional[str] = None
    target_en: Optional[str] = None
    referral_tc: Optional[str] = None
    referral_en: Optional[str] = None
    fee_tc: Optional[str] = None
    fee_en: Optional[str] = None
    wait_note_tc: Optional[str] = None
    wait_note_en: Optional[str] = None
    source_id: Optional[str] = None
    notes_tc: Optional[str] = None
    notes_en: Optional[str] = None


class ServiceUnit(BaseModel):
    unit_id: str
    name_tc: str
    name_en: Optional[str] = None
    service_code: Optional[str] = None
    operator: Optional[str] = None
    district: Optional[str] = None
    district_en: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    capacity: Optional[int] = None
    source_id: Optional[str] = None
    status: Optional[str] = None
    wait_months: Optional[int] = None  # joined from waiting_snapshot


class WaitingSnapshot(BaseModel):
    snapshot_id: str
    as_of: str
    unit_id: str
    unit_name_raw: Optional[str] = None
    service_code: Optional[str] = None
    last_match_apply: Optional[str] = None
    derived_wait_m: Optional[int] = None
    source_id: Optional[str] = None
    run_id: Optional[str] = None


class GlossaryTerm(BaseModel):
    term: str
    term_en: Optional[str] = None
    full_tc: str
    full_en: Optional[str] = None
    code: Optional[str] = None
    plain_tc: str
    plain_en: Optional[str] = None
    source_id: Optional[str] = None


class PathwayStep(BaseModel):
    step_no: int
    name_tc: str
    name_en: Optional[str] = None
    who_acts_tc: Optional[str] = None
    who_acts_en: Optional[str] = None
    preconditions: Optional[str] = None
    preconditions_en: Optional[str] = None
    duration_note: Optional[str] = None
    duration_note_en: Optional[str] = None
    friction_tc: Optional[str] = None
    friction_en: Optional[str] = None
    plain_tc: Optional[str] = None
    plain_en: Optional[str] = None
    status: Optional[str] = None


class ChecklistItem(BaseModel):
    item_id: str
    step_no: int
    name_tc: str
    name_en: Optional[str] = None
    required: Optional[int] = None
    origin_tc: Optional[str] = None
    origin_en: Optional[str] = None
    validity_tc: Optional[str] = None
    validity_en: Optional[str] = None
    sort_order: Optional[int] = None
    source_id: Optional[str] = None
    notes_tc: Optional[str] = None
    notes_en: Optional[str] = None


class RedFlag(BaseModel):
    flag_id: str
    signal_tc: str
    signal_en: Optional[str] = None
    route_tc: str
    route_en: Optional[str] = None
    route_contact: Optional[str] = None
    route_contact_en: Optional[str] = None
    never_say_tc: str
    never_say_en: Optional[str] = None
    source_id: Optional[str] = None
    status: Optional[str] = None


class Manifest(BaseModel):
    built_on: Optional[str] = None
    db_file: Optional[str] = None
    content_fingerprint: Optional[str] = None
    counts: Optional[dict] = None
