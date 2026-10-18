import json
from typing import Optional

from .config import DATA_DIR
from . import models


def _load_list(name: str) -> list:
    path = DATA_DIR / name
    if not path.exists():
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def _load_object(name: str):
    path = DATA_DIR / name
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


class Store:
    def __init__(self) -> None:
        self.manifest: Optional[models.Manifest] = None
        self.service_types: list[models.ServiceType] = []
        self.service_units: list[models.ServiceUnit] = []
        self.waiting_snapshots: list[models.WaitingSnapshot] = []
        self.glossary: list[models.GlossaryTerm] = []
        self.citable_assertions: list[models.CitableAssertion] = []
        self.pathway_steps: list[models.PathwayStep] = []
        self.checklist_items: list[models.ChecklistItem] = []
        self.red_flags: list[models.RedFlag] = []
        self._wait_map: dict[str, int] = {}
        self._service_type_map: dict[str, models.ServiceType] = {}
        self.reload()

    def reload(self) -> None:
        manifest_raw = _load_object("manifest.json")
        self.manifest = models.Manifest.model_validate(manifest_raw) if manifest_raw else None

        self.service_types = [models.ServiceType.model_validate(x) for x in _load_list("service_types.json")]
        self.waiting_snapshots = [models.WaitingSnapshot.model_validate(x) for x in _load_list("waiting_snapshot.json")]
        self.glossary = [models.GlossaryTerm.model_validate(x) for x in _load_list("glossary.json")]
        self.citable_assertions = [models.CitableAssertion.model_validate(x) for x in _load_list("citable_assertions.json")]
        self.pathway_steps = [models.PathwayStep.model_validate(x) for x in _load_list("pathway_steps.json")]
        self.checklist_items = [models.ChecklistItem.model_validate(x) for x in _load_list("checklist_items.json")]
        self.red_flags = [models.RedFlag.model_validate(x) for x in _load_list("red_flags.json")]

        self._wait_map = {
            w.unit_id: w.derived_wait_m
            for w in self.waiting_snapshots
            if w.derived_wait_m is not None
        }
        self._service_type_map = {s.code: s for s in self.service_types}

        units = [models.ServiceUnit.model_validate(x) for x in _load_list("service_units.json")]
        for u in units:
            u.wait_months = self._wait_map.get(u.unit_id)
        self.service_units = units

    def wait_months(self, unit_id: str) -> Optional[int]:
        return self._wait_map.get(unit_id)

    def service_type(self, code: str) -> Optional[models.ServiceType]:
        return self._service_type_map.get(code)

    @property
    def districts(self) -> list[str]:
        return sorted({u.district for u in self.service_units if u.district})

    @property
    def service_codes(self) -> list[str]:
        return sorted({u.service_code for u in self.service_units if u.service_code})

    @property
    def topics(self) -> list[str]:
        return sorted({a.topic for a in self.citable_assertions})

    @property
    def fingerprint(self) -> Optional[str]:
        return self.manifest.content_fingerprint if self.manifest else None


store = Store()
