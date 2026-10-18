from typing import Optional

from fastapi import APIRouter

from .store import store

router = APIRouter()


@router.get("/health")
def health() -> dict:
    return {"status": "ok", "content_fingerprint": store.fingerprint}


@router.get("/manifest")
def manifest():
    return store.manifest


@router.get("/service-types")
def service_types():
    return store.service_types


@router.get("/service-units")
def service_units(district: Optional[str] = None, service: Optional[str] = None):
    units = store.service_units
    if district:
        units = [u for u in units if u.district == district or u.district_en == district]
    if service:
        units = [u for u in units if u.service_code == service]
    return units


@router.get("/waiting-snapshots")
def waiting_snapshots():
    return store.waiting_snapshots


@router.get("/glossary")
def glossary():
    return store.glossary


@router.get("/citable-assertions")
def citable_assertions(topic: Optional[str] = None):
    if topic:
        return [a for a in store.citable_assertions if a.topic == topic]
    return store.citable_assertions


@router.get("/pathway-steps")
def pathway_steps():
    return store.pathway_steps


@router.get("/checklist-items")
def checklist_items():
    return store.checklist_items


@router.get("/red-flags")
def red_flags():
    return store.red_flags


@router.get("/districts")
def districts():
    return store.districts


@router.get("/service-codes")
def service_codes():
    return store.service_codes
