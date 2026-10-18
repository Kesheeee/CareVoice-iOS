import Foundation

/// Pick the English text when the language is English, else fall back to TC.
func localized(_ en: String?, _ tc: String?, _ language: AppLanguage) -> String {
    if language == .english, let en, !en.isEmpty { return en }
    return tc ?? en ?? ""
}

struct CitableAssertion: Codable, Identifiable {
    let assertionId: String
    let topic: String
    let quote: String
    let plainTc: String
    let locator: String?
    let org: String
    let titleTc: String
    let url: String
    let capturedOn: String
    let sourceStatus: String
    let plainEn: String?
    let quoteEn: String?
    let locatorEn: String?
    let orgEn: String?
    let titleEn: String?
    var id: String { assertionId }

    enum CodingKeys: String, CodingKey {
        case assertionId = "assertion_id"
        case topic, quote
        case plainTc = "plain_tc"
        case locator, org
        case titleTc = "title_tc"
        case url
        case capturedOn = "captured_on"
        case sourceStatus = "source_status"
        case plainEn = "plain_en"
        case quoteEn = "quote_en"
        case locatorEn = "locator_en"
        case orgEn = "org_en"
        case titleEn = "title_en"
    }
}

struct ServiceType: Codable, Identifiable {
    let code: String
    let aliasTc: String?
    let aliasEn: String?
    let nameTc: String
    let nameEn: String?
    let ageMinM: Int?
    let ageMaxM: Int?
    let intensityTc: String?
    let targetTc: String?
    let referralTc: String?
    let feeTc: String?
    let waitNoteTc: String?
    let sourceId: String?
    let notesTc: String?
    let intensityEn: String?
    let targetEn: String?
    let referralEn: String?
    let feeEn: String?
    let waitNoteEn: String?
    let notesEn: String?
    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case code
        case aliasTc = "alias_tc"
        case aliasEn = "alias_en"
        case nameTc = "name_tc"
        case nameEn = "name_en"
        case ageMinM = "age_min_m"
        case ageMaxM = "age_max_m"
        case intensityTc = "intensity_tc"
        case targetTc = "target_tc"
        case referralTc = "referral_tc"
        case feeTc = "fee_tc"
        case waitNoteTc = "wait_note_tc"
        case sourceId = "source_id"
        case notesTc = "notes_tc"
        case intensityEn = "intensity_en"
        case targetEn = "target_en"
        case referralEn = "referral_en"
        case feeEn = "fee_en"
        case waitNoteEn = "wait_note_en"
        case notesEn = "notes_en"
    }
}

struct ServiceUnit: Codable, Identifiable {
    let unitId: String
    let nameTc: String
    let nameEn: String?
    let serviceCode: String?
    let operatorName: String?
    let district: String?
    let address: String?
    let phone: String?
    let capacity: Int?
    let sourceId: String?
    let status: String?
    let districtEn: String?
    var id: String { unitId }

    enum CodingKeys: String, CodingKey {
        case unitId = "unit_id"
        case nameTc = "name_tc"
        case nameEn = "name_en"
        case serviceCode = "service_code"
        case operatorName = "operator"
        case district, address, phone, capacity
        case sourceId = "source_id"
        case status
        case districtEn = "district_en"
    }
}

struct WaitingSnapshot: Codable, Identifiable {
    let snapshotId: String
    let asOf: String
    let unitId: String
    let unitNameRaw: String?
    let serviceCode: String?
    let lastMatchApply: String?
    let derivedWaitM: Int?
    let sourceId: String?
    let runId: String?
    var id: String { snapshotId }

    enum CodingKeys: String, CodingKey {
        case snapshotId = "snapshot_id"
        case asOf = "as_of"
        case unitId = "unit_id"
        case unitNameRaw = "unit_name_raw"
        case serviceCode = "service_code"
        case lastMatchApply = "last_match_apply"
        case derivedWaitM = "derived_wait_m"
        case sourceId = "source_id"
        case runId = "run_id"
    }
}

struct GlossaryTerm: Codable, Identifiable {
    let term: String
    let fullTc: String
    let code: String?
    let plainTc: String
    let sourceId: String?
    let termEn: String?
    let fullEn: String?
    let plainEn: String?
    var id: String { term }

    enum CodingKeys: String, CodingKey {
        case term
        case fullTc = "full_tc"
        case code
        case plainTc = "plain_tc"
        case sourceId = "source_id"
        case termEn = "term_en"
        case fullEn = "full_en"
        case plainEn = "plain_en"
    }
}

struct PathwayStep: Codable, Identifiable {
    let stepNo: Int
    let nameTc: String
    let whoActsTc: String?
    let preconditions: String?
    let durationNote: String?
    let frictionTc: String?
    let plainTc: String?
    let status: String?
    let nameEn: String?
    let whoActsEn: String?
    let preconditionsEn: String?
    let durationNoteEn: String?
    let frictionEn: String?
    let plainEn: String?
    var id: Int { stepNo }

    enum CodingKeys: String, CodingKey {
        case stepNo = "step_no"
        case nameTc = "name_tc"
        case whoActsTc = "who_acts_tc"
        case preconditions
        case durationNote = "duration_note"
        case frictionTc = "friction_tc"
        case plainTc = "plain_tc"
        case status
        case nameEn = "name_en"
        case whoActsEn = "who_acts_en"
        case preconditionsEn = "preconditions_en"
        case durationNoteEn = "duration_note_en"
        case frictionEn = "friction_en"
        case plainEn = "plain_en"
    }
}

struct ChecklistItem: Codable, Identifiable {
    let itemId: String
    let stepNo: Int
    let nameTc: String
    let required: Int?
    let originTc: String?
    let validityTc: String?
    let sortOrder: Int?
    let sourceId: String?
    let notesTc: String?
    let nameEn: String?
    let originEn: String?
    let validityEn: String?
    let notesEn: String?
    var id: String { itemId }

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case stepNo = "step_no"
        case nameTc = "name_tc"
        case required
        case originTc = "origin_tc"
        case validityTc = "validity_tc"
        case sortOrder = "sort_order"
        case sourceId = "source_id"
        case notesTc = "notes_tc"
        case nameEn = "name_en"
        case originEn = "origin_en"
        case validityEn = "validity_en"
        case notesEn = "notes_en"
    }
}

struct RedFlag: Codable, Identifiable {
    let flagId: String
    let signalTc: String
    let routeTc: String
    let routeContact: String?
    let neverSayTc: String
    let sourceId: String?
    let status: String?
    let signalEn: String?
    let routeEn: String?
    let routeContactEn: String?
    let neverSayEn: String?
    var id: String { flagId }

    enum CodingKeys: String, CodingKey {
        case flagId = "flag_id"
        case signalTc = "signal_tc"
        case routeTc = "route_tc"
        case routeContact = "route_contact"
        case neverSayTc = "never_say_tc"
        case sourceId = "source_id"
        case status
        case signalEn = "signal_en"
        case routeEn = "route_en"
        case routeContactEn = "route_contact_en"
        case neverSayEn = "never_say_en"
    }
}

struct ContentManifest: Codable {
    let builtOn: String?
    let dbFile: String?
    let contentFingerprint: String?
    let counts: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case builtOn = "built_on"
        case dbFile = "db_file"
        case contentFingerprint = "content_fingerprint"
        case counts
    }
}

struct GovernmentContent {
    let assertions: [CitableAssertion]
    let serviceTypes: [ServiceType]
    let serviceUnits: [ServiceUnit]
    let waiting: [WaitingSnapshot]
    let glossary: [GlossaryTerm]
    let pathwaySteps: [PathwayStep]
    let checklistItems: [ChecklistItem]
    let redFlags: [RedFlag]
    let manifest: ContentManifest?

    static func load() -> GovernmentContent {
        func decode<T: Decodable>(_ name: String, _ type: T.Type) -> T? {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json") else { return nil }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return GovernmentContent(
            assertions: decode("citable_assertions", [CitableAssertion].self) ?? [],
            serviceTypes: decode("service_types", [ServiceType].self) ?? [],
            serviceUnits: decode("service_units", [ServiceUnit].self) ?? [],
            waiting: decode("waiting_snapshot", [WaitingSnapshot].self) ?? [],
            glossary: decode("glossary", [GlossaryTerm].self) ?? [],
            pathwaySteps: decode("pathway_steps", [PathwayStep].self) ?? [],
            checklistItems: decode("checklist_items", [ChecklistItem].self) ?? [],
            redFlags: decode("red_flags", [RedFlag].self) ?? [],
            manifest: decode("manifest", ContentManifest.self)
        )
    }

    func waitMonths(for unitId: String) -> Int? {
        waiting.first { $0.unitId == unitId }?.derivedWaitM
    }

    func serviceType(code: String?) -> ServiceType? {
        guard let code else { return nil }
        return serviceTypes.first { $0.code == code }
    }

    var districts: [String] {
        let values = serviceUnits.compactMap { $0.district }.filter { !$0.isEmpty }
        return Array(Set(values)).sorted()
    }

    var serviceCodes: [String] {
        let values = serviceUnits.compactMap { $0.serviceCode }.filter { !$0.isEmpty }
        return Array(Set(values)).sorted()
    }
}
