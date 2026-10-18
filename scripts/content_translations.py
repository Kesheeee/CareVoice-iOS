#!/usr/bin/env python3
"""Shared English translation maps + apply function for the curated content JSONs.

Machine-assisted translations, for the demo only. Replace with Harmon's official
English later. Used by scripts/translate_content.py (iOS bundle) and
backend/scripts/sync_data.py (FastAPI data dir).
"""
import json
from pathlib import Path

ORG = {
    "社署": "Social Welfare Department",
    "衞生署": "Department of Health",
    "立法會": "Legislative Council",
    "政府新聞網（食衞局）": "Government news portal (Food and Health Bureau)",
    "社署（資料源自政府統計處）": "Social Welfare Department (source: Census and Statistics Department)",
}

TITLE = {
    "特殊幼兒中心（服務頁）": "Special Child Care Centre (service page)",
    "康復服務中央轉介系統 — 輪候資料更新": "Central Referral System for Rehabilitation Services — Waiting List Information Updates",
    "《為輪候資助學前康復服務的兒童提供學習訓練津貼》簡介（2026年10月修訂版）": "Training Subsidy Programme Brief (Oct 2026 revision)",
    "兒童體能智力測驗服務《服務範圍》": "Child Assessment Service — Scope of Service",
    "LCQ22: Special child care centres（2025-03-19 書面答覆．英文版）": "LCQ22: Special child care centres (19 Mar 2025 written reply, English version)",
    "到校學前康復服務（OPRS）": "On-site Pre-school Rehabilitation Services (OPRS)",
    "為輪候資助學前康復服務的兒童提供學習訓練津貼（服務頁）": "Training Subsidy Programme (service page)",
    "按家庭人數釐定的家庭住戶每月收入中位數——百分之七十五（二零二六年第二季）": "Household Monthly Income Median by household size — 75th percentile (2026 Q2)",
    "學習訓練津貼認可服務機構名單（高額津貼）（最後更新 2026年10月）": "List of Recognised Service Operators for the Training Subsidy (higher subsidy) (last updated Oct 2026)",
    "學習訓練津貼認可服務機構名單（普通津貼）（最後更新 2026年10月）": "List of Recognised Service Operators for the Training Subsidy (normal subsidy) (last updated Oct 2026)",
    "立法會二十二題：特殊幼兒中心（2025-03-19 書面答覆）": "Legislative Council Question 22: Special child care centres (19 Mar 2025 written reply)",
    "立法會十八題：支援有特殊需要的兒童（2020-02-26 書面答覆）": "Legislative Council Question 18: Support for children with special needs (26 Feb 2020 written reply)",
    "《齊心支援 讓兒童健康成長》": "Supporting children to grow up healthy",
}

LOCATOR = {
    "申請手續": "Application procedures",
    "費用": "Fee",
    "服務對象": "Service targets",
    "服務對象（末段）": "Service targets (last paragraph)",
    "第4頁．受惠對象條件(2)": "p.4 Eligibility conditions (2)",
    "一．服務對象": "1. Service targets",
    "簡介段": "Introduction paragraph",
    "服務簡介．第4段": "Service introduction, paragraph 4",
    "第1頁．資助水平及服務": "p.1 Subsidy levels and services",
    "註一": "Note 1",
    "註二": "Note 2",
    "第1頁．資助水平及服務（高額津貼）": "p.1 Subsidy levels and services (higher subsidy)",
    "單頁表格（逐格抄錄，非連續句子）": "Single-page table (transcribed cell by cell, not a continuous sentence)",
    "第1頁．資助水平及服務（普通津貼）": "p.1 Subsidy levels and services (normal subsidy)",
    "每頁頁首標題（共12頁）": "Page-header title (12 pages)",
    "第(一)及(二)部分": "Parts (1) and (2)",
    "第1頁．經中央轉介系統編配服務": "p.1 Service allocation via the Central Referral System",
    "回覆(二)及(三)．學前康復服務表": "Reply (2) and (3), Pre-school rehabilitation services table",
    "回覆(二)及(三)．學前康復服務表下註": "Note under the pre-school rehabilitation services table, Reply (2) and (3)",
    "第六段（儿童体能智力测验服务一节）": "Paragraph 6 (Child Assessment Service section)",
}

DISTRICT = {
    "中西區": "Central and Western", "九龍城": "Kowloon City", "元朗": "Yuen Long",
    "北區": "North", "南區": "Southern", "大埔": "Tai Po", "屯門": "Tuen Mun",
    "東區": "Eastern", "沙田": "Sha Tin", "油尖旺": "Yau Tsim Mong",
    "深水埗": "Sham Shui Po", "灣仔": "Wan Chai", "荃灣": "Tsuen Wan",
    "葵青": "Kwai Tsing", "西貢": "Sai Kung", "觀塘": "Kwun Tong",
    "離島": "Islands", "黃大仙": "Wong Tai Sin",
}

# assertion_id -> (plain_en, quote_en)
ASSERT = {
    "A-005": (
        "Applications go through the Central Referral System, referred by a social worker or rehabilitation unit staff; applying is free, and the service itself is free.",
        "Referred to the SWD Central Referral System for Rehabilitation Services by a social worker or a staff member of a rehabilitation service unit. No fee is charged for the application.",
    ),
    "A-027": (
        "The service itself is free.",
        "Free of charge.",
    ),
    "A-003": (
        "A child can be placed in an S-place if they are aged 2 to under 6, not yet in primary school, and have a moderate to severe disability — one of which is explicitly autism.",
        "Children aged 2 to under 6 who have not yet started primary education and have any one of the following developmental disabilities:",
    ),
    "A-004": (
        "A child under 2 can register to queue in advance, but when a vacancy comes up the child must already have turned 2 to be offered a place.",
        "The Central Referral System for Rehabilitation Services accepts parents to register in advance for this service for children under the age of 2, but when a vacancy arises, these children must meet the basic admission conditions, including having reached the age of 2, before a place can be allocated.",
    ),
    "A-007": (
        "For a child under 2, parents can register in advance on the Central Referral System to queue for an S-place or I-place.",
        "Central Referral System for Rehabilitation Services (the System) accepts parents to register application for Special Child Care Centre or Integrated Programme in Kindergarten-cum-Child Care Centre services for children from below the age of two in advance.",
    ),
    "A-021": (
        "To get the T-place subsidy, the child must not be receiving any subsidised pre-school rehabilitation service, including the 'transitional E-place'.",
        "Not receiving any subsidised pre-school rehabilitation service, including the 'Transitional Early Education and Training Centre' or the 'Pre-school Rehabilitation Service – School-based Support Model'.",
    ),
    "A-022": (
        "One of the disability conditions: moderate or severe intellectual disability.",
        "Moderate or severe intellectual disability;",
    ),
    "A-023": (
        "One of the disability conditions: moderate or severe physical disability.",
        "Moderate or severe physical disability;",
    ),
    "A-024": (
        "One of the disability conditions: deafness or severe to profound hearing impairment.",
        "Deafness or severe to profound hearing impairment;",
    ),
    "A-025": (
        "One of the disability conditions: blindness or severe visual impairment.",
        "Blindness or severe visual impairment; or",
    ),
    "A-026": (
        "One of the disability conditions: serious behavioural or emotional problems, hyperactivity, or autism — the official basis for 'a child with autism goes down the S-route'.",
        "Serious behavioural/emotional problems, a tendency to hyperactivity, or autism.",
    ),
    "A-015": (
        "To get an assessment at the Child Assessment Centre, you first need a referral from a professional such as a doctor or psychologist, or a direct hospital referral. Parents cannot book on their own.",
        "Children may be referred by professionals (such as doctors or psychologists) or directly through a hospital (e.g. premature infants).",
    ),
    "A-002": (
        "An S-place is full-day: the child spends the whole day at the centre receiving training and care from a professional team, with the goal of preparing for primary school.",
        "Providing full-day training and care to children with moderate to severe disabilities, to help them develop and grow and prepare them for primary education.",
    ),
    "A-009": (
        "There are 50 S-place centres in Hong Kong, 6 of which are residential, providing full-day training and care for children aged 2–6 with moderate to severe disabilities.",
        "As of the end of January 2025, there are 50 Special Child Care Centres (SCCCs), including six Residential Special Child Care Centres, across the territory providing full-day training and care for children aged two to six with moderate to severe disabilities.",
    ),
    "A-032": (
        "The O-place (on-site pre-school rehabilitation service) is delivered by an NGO multidisciplinary team directly at the kindergarten, for children under 6 assessed with mild disabilities or suspected special needs.",
        "The service is provided by a multidisciplinary service team operated by a non-governmental organisation (comprising occupational therapists, physiotherapists, speech therapists, clinical/educational psychologists, social workers and special child care workers) through a school-based integrated model, delivering on-site training and support to children under 6 attending a kindergarten or kindergarten-cum-child care centre participating in the 'On-site Pre-school Rehabilitation Service', who have been assessed with mild disabilities or are suspected of having special needs.",
    ),
    "A-011": (
        "The T-place subsidy is not paid in cash to parents. SWD pays it in two tiers, based on the child's disability, directly to recognised service operators; parents receive the training services those operators provide.",
        "The Training Subsidy is not paid directly to the parent/guardian, but to recognised service operators, and is provided at the following two levels according to the child's degree of disability:",
    ),
    "A-012": (
        "From 1 Oct 2026, new applicants for the O-place (on-site pre-school rehabilitation service) can no longer apply for the T-place subsidy — because the O-place has reached zero waiting.",
        "As the 'On-site Pre-school Rehabilitation Service' has reached zero waiting, from 1 October 2026 children newly applying for the 'On-site Pre-school Rehabilitation Service' are not beneficiaries of the 'Training Subsidy Programme'.",
    ),
    "A-013": (
        "From 1 Apr 2027, new applicants for the I-place (integrated programme) are no longer eligible for the T-place subsidy — because the I-place will be served directly through the school-based support model without queueing.",
        "With the progressive implementation of the 'School-based Support Model', eligible children of the 'Integrated Programme in Kindergarten-cum-Child Care Centre' will receive services directly through the school-based support model without going through the Central Referral System. Therefore, from 1 April 2027, children newly applying for the 'Integrated Programme in Kindergarten-cum-Child Care Centre' are not beneficiaries of the 'Training Subsidy Programme'.",
    ),
    "A-016": (
        "The higher subsidy (for children waiting for an S-place) buys: 6 sessions totalling 6 hours per month of individual or group training/therapy, including at least 18 hours every 6 months by occupational/physiotherapists or speech therapists.",
        "Six sessions totalling six hours per month of individual or group training/therapy services provided by special child care workers, clinical/educational psychologists or occupational/physiotherapists/speech therapists (including balanced groups with parents/guardians/carers), of which at least eighteen hours every six months are provided by occupational/physiotherapists/speech therapists;",
    ),
    "A-018": (
        "The income threshold for the T-place subsidy is 'household monthly income not exceeding 75% of the median monthly household income'. 2026 Q2 figures: 1 person $8,250, 2 people $18,000, 3 people $30,300, 4 people $40,800, 5 or more $39,225. Families waiting for an S-place are exempt from the means test.",
        "Median monthly household income by household size (HK$) (2026 Q2) (for the means test of the 'Training Subsidy Programme' only)\n1 | $8,250\n2 | $18,000\n3 | $30,300\n4 | $40,800\n5 or more | $39,225",
    ),
    "A-020": (
        "The normal subsidy (for children waiting for an E-place/I-place) buys: 4 sessions totalling 3 hours per month of training or therapy.",
        "Four sessions totalling three hours per month of individual or group training/therapy services provided by special child care workers, clinical/educational psychologists or occupational/physiotherapists/speech therapists (including balanced groups with parents/guardians/carers);",
    ),
    "A-030": (
        "SWD has published a list of recognised service operators: children receiving the higher subsidy (waiting for an S-place) can choose an operator from this list to use the Training Subsidy; the list was last updated in October 2026.",
        "List of recognised service operators providing higher-subsidy places under the Training Subsidy Programme for children waiting for subsidised pre-school rehabilitation services.",
    ),
    "A-031": (
        "SWD has published a list of recognised service operators: children receiving the normal subsidy (waiting for an E-place/I-place) can choose an operator from this list to use the Training Subsidy; the list was last updated in October 2026.",
        "List of recognised service operators providing normal-subsidy places under the Training Subsidy Programme for children waiting for subsidised pre-school rehabilitation services.",
    ),
    "A-008": (
        "Children waiting for an S-place who are not using transition services can apply for the Training Subsidy (T-place) without a means test, and use the subsidy to buy self-financed pre-school rehabilitation services from recognised operators to start training sooner.",
        "Children waiting for a Special Child Care Centre who are not receiving the above transition services may apply for the 'Training Subsidy Programme for children waiting for subsidised pre-school rehabilitation services' without a household means test. They can use the subsidy to access self-financed pre-school rehabilitation services operated by recognised service operators to start training as early as possible.",
    ),
    "A-010": (
        "While queueing for an S-place, the child can simultaneously apply for and receive an E-place or O-place transition service, until an S-place is allocated. In other words, the child doesn't have to wait idle.",
        "To allow children with special needs to receive training and support as early as possible, they may, while waiting for a Special Child Care Centre place, simultaneously apply for and receive transition services from an Early Education and Training Centre or the On-site Pre-school Rehabilitation Service, until they are allocated a Special Child Care Centre place.",
    ),
    "A-006": (
        "Waiting is ordered by application date (plus district preference). So registering one day earlier puts you one place ahead.",
        "Upon receipt of vacancy reports from service units, the System will select eligible children on the waiting list for admission to the services according to the order of their dates of application and location preference normally.",
    ),
    "A-014": (
        "Officially computed average waits: in 2018/19, E-place 16.6 months, I-place 12.6 months, S-place 18.4 months.",
        "In 2018/19, the average waiting times of various subsidised pre-school rehabilitation services were as follows:\nEarly Education and Training Centre | 16.6\nIntegrated Programme in Kindergarten-cum-Child Care Centre | 12.6\nSpecial Child Care Centre | 18.4\nOn-site Pre-school Rehabilitation Service | Not applicable (note)",
    ),
    "A-019": (
        "While using the T-place subsidy, if you are allocated a service and refuse it, the child's subsidised pre-school rehabilitation application will be removed from the waiting list — meaning you have to queue again.",
        "However, if a beneficiary child refuses a service allocated through the Central Referral System, the child's application for subsidised pre-school rehabilitation services will be removed from the waiting list.",
    ),
    "A-028": (
        "Note under the table: average waiting time is computed by financial year (1 Apr to 31 Mar); because the On-site Pre-school Rehabilitation Service was regularised in October 2018, there is no full 2018/19 figure.",
        "Note: Average waiting time is computed by financial year (i.e. from 1 April each year to 31 March the following year). As the On-site Pre-school Rehabilitation Service was regularised in October 2018, there is no full-year 2018/19 figure.",
    ),
    "A-001": (
        "While waiting for assessment and services, the official support is transition support such as talks, workshops and training courses; home training for the child is the parents' own responsibility.",
        "The Assessment Service also provides parents with short-term transitional support services, such as talks, workshops and training courses, to deepen parents' understanding of their child's condition and help them master more effective ways of caring for their child, so as to carry out home training and support the child's development.",
    ),
}

SERVICE_TYPE = {
    "CAS": ("Children under 12 with developmental disabilities or behavioural problems", "Assessment and diagnosis (not training)", "Referral by a professional (e.g. doctor, psychologist) or directly through a hospital", "To be confirmed", "Official figure: new registrations are offered an appointment within three weeks (2019 figure — state the year)", "The first door of the whole parent journey. The service covers children under 12, but referral to SWD pre-school rehabilitation only covers under 6 — the origin of the 0–6 scope."),
    "E": ("Children from birth to under 6 with relatively mild developmental disabilities (ages 0–2 also accepted)", "Part-time (hourly sessions, like tutoring)", "Referral by a social worker or rehabilitation service unit staff to the SWD Central Referral System", "To be confirmed (no fee statement captured from the official page)", "Recalculated per centre (Aug 2026): 38 of 64 centres show a placement that month; median 0 months, longest 6 months", "One of the most important terms in parent circles. E-place can be used as a transition service while waiting for an S-place."),
    "I": ("Children with mild disabilities", "Training and care within a mainstream kindergarten/child care centre", "Via the Central Referral System", "To be confirmed", "Official figure: average wait 12.6 months in 2018/19 (historical — state the year)", "From 1 Apr 2027 new applicants are no longer eligible for the Training Subsidy (see SRC-005 note 2)."),
    "O": ("Children suspected of special needs (including those awaiting CAS assessment), and children assessed with mild disabilities", "On-site training, consultation and teacher/parent support by an NGO multidisciplinary team", "First-tier support does not require the Central Referral System; those assessed by recognised professionals are referred by a designated service unit social worker", "Free", "Has reached 'zero waiting' (official — see SRC-005 note 1)", "From 1 Oct 2026 new applicants are no longer eligible for the Training Subsidy — because zero waiting has been reached. This is also the best example of a rule having an effective date."),
    "S": ("Children aged 2 to under 6 with moderate to severe disabilities, including autism", "Full-day training and care (like a full-day kindergarten, with a professional team all day)", "Referral by a social worker or rehabilitation service unit staff to the SWD Central Referral System", "Free", "Recalculated per centre (Aug 2026): 60 service units; median 4 months, 28% over 12 months, longest 48 months; official figure: average wait 19.2 months in 2023–24", "The gap with E-place is this project's core original finding (two queues on the same street, ten times apart)."),
    "SR": ("Children with moderate or severe disabilities who do not need frequent medical/hospital care, or whose home environment is unsuitable for care", "Continuous training and residential care", "Same as S-place, via the Central Referral System", "To be confirmed", "Official figure: 6 residential special child care centres territory-wide (out of 50 SCCCs)", "Few in number, usually longer waits; the longest 48-month figure in the Aug 2026 recalculation appears in this category."),
    "T": ("Children under 6 who are on the Central Referral System waiting list and not receiving any subsidised pre-school rehabilitation service", "Cash subsidy (to buy self-financed training services from recognised operators)", "SWD sends letters inviting eligible children's parents/guardians to apply (not obtained by parents proactively queueing)", "Fully free (no application fee)", "Not applicable (not a queue-based service)", "Normal subsidy: up to $3,549/month (waiting E/I/O, means-tested); higher subsidy: up to $6,904/month (waiting S-place, no means test). 'Waiting has a price tag' — pitch material."),
}

GLOSSARY = {
    "CAC／測驗中心": ("Child Assessment Centre, Department of Health", "Where assessment happens, not training. 7 across Hong Kong, by district. You need a referral letter from a doctor or psychologist."),
    "EETC": ("Early Education and Training Centre", "The English abbreviation for Early Education and Training Centre, used in the official waiting dataset — the 'E-place'."),
    "E位": ("Early Education and Training Centre", "Like tutoring: a few visits a week, about an hour each, one-to-one training by therapists or special child care workers. For children with milder needs who are at home or in a mainstream kindergarten."),
    "I位": ("Integrated Programme in Kindergarten-cum-Child Care Centre", "Adds training and care for mildly disabled children within a mainstream kindergarten, so they attend with typically developing peers."),
    "OPRS": ("On-site Pre-school Rehabilitation Services", "The abbreviation for On-site Pre-school Rehabilitation Services — the 'O-place'."),
    "O位": ("On-site Pre-school Rehabilitation Services", "An NGO multidisciplinary team delivers training directly at the kindergarten, so parents don't shuttle children to a centre. Already at 'zero waiting'."),
    "SCCC": ("Special Child Care Centre", "The abbreviation for Special Child Care Centre, used in the official waiting dataset — the 'S-place'."),
    "S位": ("Special Child Care Centre", "Like a full-day special kindergarten: the child attends daily for all-day training and care by a multidisciplinary team. For ages 2–6 with moderate to severe disabilities; autism is usually placed here after assessment."),
    "S位＋住宿": ("Residential Special Child Care Centre", "Same as S-place but with residential care. Only 6 territory-wide; waits are usually longer."),
    "TSP": ("Training Subsidy Programme", "The abbreviation for the Training Subsidy Programme — the 'T-place'."),
    "T位": ("Training Subsidy Programme", "Not a service, but money. While queueing, use the cash subsidy to buy training sessions from recognised operators. Two tiers: normal and higher."),
    "中央轉介系統／CRSRS": ("Central Referral System for Rehabilitation Services (pre-school children sub-system)", "The queueing system. All government-subsidised pre-school rehabilitation services are allocated here. 'Getting on the list' means completing registration here, not merely seeing a doctor."),
    "住宿S位": ("Residential Special Child Care Centre", "A special child care centre that also provides residential care. Only 6 territory-wide; waits usually longer."),
    "個案工作員": ("Case worker of the Social Welfare Department / NGO", "The social worker who handles your paperwork. Referral letters and Central Referral System registration mostly pass through them."),
    "兼收計劃": ("Integrated Programme in Kindergarten-cum-Child Care Centre", "Lets mildly disabled children attend a mainstream kindergarten while receiving training."),
    "普通津貼": ("Training Subsidy Programme (normal subsidy)", "The normal tier of the T-place subsidy, for households with slightly higher income."),
    "輪候期間的過渡服務": ("Transitional services", "While waiting for an S-place, you can simultaneously use an E-place or O-place until an S-place opens. Many parents don't know this at all."),
    "醫務社工": ("Medical social worker of the Social Welfare Department / Hospital Authority", "A social worker based in a hospital. If your child is on the hospital route, they usually make the referral with psychological and medical reports."),
    "預早登記": ("Advance registration scheme", "A mechanism to join the queue before age 2, so you don't wait until the child turns 2."),
    "高額津貼": ("Training Subsidy Programme (higher subsidy)", "The higher tier of the T-place subsidy, for households with lower income."),
}

PATHWAY = {
    1: ("Noticing something is off (delays in language / social / behavioural milestones)", "Parent / carer / kindergarten teacher", "—", "Parents usually start to wonder between 1.5 and 4 years old", "Not sure whether it counts as a problem or how serious it is; fear of being seen as a bad parent; others saying 'they'll grow out of it'", "This step has no official entry point. Parents are entirely on their own to judge — so it is easiest to be delayed by months."),
    2: ("Getting a referral letter from a professional", "Parent → private doctor / family doctor / psychologist / Maternal & Child Health Centre", "The child's developmental concerns have been raised with a professional", "Depends on whether you can get a doctor's appointment", "Not knowing the rule that 'a doctor's referral is required for assessment', and waiting in vain; the usual family doctor may not be willing to write one", "To take a child for assessment, you first need a referral letter from a doctor or psychologist. Parents cannot queue at the assessment centre directly."),
    3: ("Registering and assessment at the Department of Health Child Assessment Centre", "Parent brings the child; the centre's multidisciplinary team carries it out", "Already holds a professional referral letter", "Official figure: an appointment within three weeks of registration for new cases (2019 figure)", "Not knowing which documents to bring, that the first visit has a fee, and to bring a recent photo and the health centre record book", "Bring all the documents to register at the assessment centre for your district; the centre will arrange a time for a comprehensive assessment."),
    4: ("Assessment result and referral decision", "The assessment centre's assessment team", "Assessment completed", "—", "Not knowing what happens after assessment, how long to wait, or whether there will be follow-up", "After assessment, the doctor decides which service route to refer the child to — this step determines which queue you join next."),
    5: ("Registering on the Central Referral System (CRSRS)", "The referrer (social worker / medical social worker / rehabilitation unit staff) registers on the family's behalf", "Assessment result already available (with psychological/medical reports)", "—", "Parents often think 'seeing the doctor means you're on the list', but you're only on the list once a social worker completes Central Referral System registration; nobody tells you about the gap in between", "A social worker enters your application into the Central Referral System — this is the moment you are truly 'on the list'. The 'time to get on the list' metric is measured up to here."),
    6: ("Transition arrangements while waiting (E-place / O-place / T-place subsidy)", "Parent applies; social worker assists", "Already on the Central Referral System waiting list", "Can last until an S-place becomes available", "Most parents don't know: while waiting for an S-place you can simultaneously use an E-place or O-place; and if not using a transition service you can receive the T-place subsidy without a means test", "While waiting for an S-place, the child can simultaneously apply for an E-place or O-place transition; and if not using a transition service, you can apply for the Training Subsidy (T-place) to buy training. The child doesn't have to wait idle."),
    7: ("Service allocation (or changing service type / centre choice)", "The Central Referral System allocates by application date and district preference", "On the waiting list and meeting basic admission conditions (including age 2)", "—", "Not knowing you can change service type or centre choice midway; not knowing whether moving house / changing district requires requeueing", "When a place opens, the system allocates it by your application date order plus your district preference."),
}

CHECKLIST = {
    "CI-001": ("Referral letter from a doctor or psychologist", "Issued by: private doctor / hospital / psychologist", "To be confirmed", "Without this letter, step 3 can't proceed. It's the first thing parents most often lack."),
    "CI-002": ("Child's birth certificate or identity card (original required)", "Kept by the parent", "—", "Official requirement is the original; photocopies not accepted."),
    "CI-003": ("Father's and mother's identity cards (or photocopies)", "Kept by the parent", "—", None),
    "CI-004": ("1 recent half-length photo of the child", "Prepared by the parent", "—", "Most easily forgotten, and hard to retake at the last minute."),
    "CI-005": ("Health centre record book / immunisation record / all specialist follow-up cards", "Department of Health Maternal & Child Health Centre / hospital", "—", "Records the child's developmental surveillance data over time; useful for assessment."),
    "CI-006": ("Proof of address (or photocopy)", "Prepared by the parent", "—", "Determines which district's assessment centre you are assigned to."),
    "CI-007": ("Specialist clinic fee (first visit $135, subsequent $80) or a valid CSSA medical fee waiver certificate", "Paid on site", "—", "Amount and CSSA waiver now cite a Department of Health first-hand source (SRC-022 registration form PDF). Filename carries a version tag; externally state 'as listed on the Department of Health registration form', not 'current fee'. Families with a CSSA waiver are exempt."),
    "CI-008": ("Psychological report / medical report (submitted by the referrer)", "Assessment team / doctor / referrer", "To be confirmed", "Parents don't prepare this themselves, but should confirm the referrer submitted it along."),
    "CI-009": ("Service type (E/S/I/O) and centre district preference", "Provided by the parent at registration", "—", "Official text states allocation is by 'application date and district preference' — so a wrong district preference directly affects when you get a place."),
    "CI-010": ("Training Subsidy (T-place) application form with copies of required documents", "Filled in and submitted by the parent after SWD sends an invitation letter", "—", "You won't get it unless you apply; SWD invites eligible families by letter, but parents must submit the form. Can be submitted online or by post."),
}

RED_FLAG = {
    "RF-001": ("The child shows self-injury (head-banging, biting, scratching) or aggression toward others", "Contact the child's treating doctor immediately; in an emergency go to the nearest A&E or call 999", "999 (emergency) | SWD hotline 2343 2255 (24 hours)", "Never say 'this is typical autistic behaviour, just endure it' or 'they'll grow out of it'. The system does not judge the cause of the behaviour; it only directs the parent to real human professional support."),
    "RF-002": ("The child has convulsions, altered consciousness, suddenly cannot be woken, or abnormal breathing", "Call 999 or go to A&E immediately", "999", "Do not make any explanatory or reassuring judgement. The system only routes, and does not comment on symptoms."),
    "RF-003": ("The child shows skill regression — previously spoken words or performed actions disappear", "See a family doctor or Maternal & Child Health Centre soon and ask for referral to the Department of Health Child Assessment Service", "Department of Health Child Assessment Service (referral by doctor or psychologist required)", "Do not say 'regression is normal' or 'wait and see'. Skill regression needs real human assessment, not an app's opinion."),
    "RF-004": ("The caregiver has thoughts of self-harm, emotional breakdown, or says they 'can't carry on'", "Seek real human support immediately: SWD hotline, Hospital Authority mental health hotline, suicide prevention hotline, or go to the nearest A&E", "SWD hotline 2343 2255 (24h) | HA Mental Health Direct 2466 7350 (24h) | Suicide Prevention Services 2382 0000 (24h) | The Samaritans HK 2389 2222 (24h) | Caritas Family Crisis Line 18288 (24h) | Emergency: 999 / A&E", "Never judge the parent (e.g. 'think positive'). The last thing a parent in breakdown needs is to be judged — this is the first red line of this project's copy."),
    "RF-005": ("The parent asks the system to judge 'is my child autistic'", "Clearly state that the app does not diagnose, and direct to formal assessment at the Department of Health Child Assessment Service (referral by doctor or psychologist required)", "Department of Health Child Assessment Service", "Do not say 'your child is probably autistic' or any expression implying diagnosis. The system only organises facts and presents information; the judgement belongs to professional assessment."),
}


SERVICE_TYPE_ALIAS = {
    "CAS": "CAS", "E": "EETC", "I": "ICCC", "O": "OPRS", "S": "SCCC", "SR": "RSCCC", "T": "TSP",
}

GLOSSARY_TERM = {
    "CAC／測驗中心": "CAC",
    "EETC": "EETC",
    "E位": "EETC",
    "I位": "ICCC",
    "OPRS": "OPRS",
    "O位": "OPRS",
    "SCCC": "SCCC",
    "S位": "SCCC",
    "S位＋住宿": "RSCCC",
    "TSP": "TSP",
    "T位": "TSP",
    "中央轉介系統／CRSRS": "Central Referral System (CRSRS)",
    "住宿S位": "RSCCC",
    "個案工作員": "Case worker",
    "兼收計劃": "Integrated Programme",
    "普通津貼": "Normal subsidy",
    "輪候期間的過渡服務": "Transitional services",
    "醫務社工": "Medical social worker",
    "預早登記": "Advance registration",
    "高額津貼": "Higher subsidy",
}


def apply_to(data_dir: Path) -> list[str]:
    """Add *_en fields to the content JSONs in data_dir. Returns files touched."""
    def load(name):
        return json.load(open(data_dir / name, encoding="utf-8"))
    def save(name, data):
        with open(data_dir / name, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    a = load("citable_assertions.json")
    for it in a:
        pid = it["assertion_id"]
        p, q = ASSERT[pid]
        it["plain_en"] = p
        it["quote_en"] = q
        it["org_en"] = ORG.get(it.get("org"), it.get("org"))
        it["title_en"] = TITLE.get(it.get("title_tc"), it.get("title_tc"))
        if it.get("locator") in LOCATOR:
            it["locator_en"] = LOCATOR[it["locator"]]
    save("citable_assertions.json", a)

    st = load("service_types.json")
    for it in st:
        t, i, r, f, w, n = SERVICE_TYPE[it["code"]]
        it["alias_en"] = SERVICE_TYPE_ALIAS[it["code"]]
        it["target_en"] = t; it["intensity_en"] = i; it["referral_en"] = r
        it["fee_en"] = f; it["wait_note_en"] = w; it["notes_en"] = n
    save("service_types.json", st)

    g = load("glossary.json")
    for it in g:
        f, p = GLOSSARY[it["term"]]
        it["term_en"] = GLOSSARY_TERM[it["term"]]
        it["full_en"] = f; it["plain_en"] = p
    save("glossary.json", g)

    su = load("service_units.json")
    for it in su:
        if it.get("district") in DISTRICT:
            it["district_en"] = DISTRICT[it["district"]]
    save("service_units.json", su)

    pw = load("pathway_steps.json")
    for it in pw:
        n, w, p, d, fr, pl = PATHWAY[it["step_no"]]
        it["name_en"] = n; it["who_acts_en"] = w; it["preconditions_en"] = p
        it["duration_note_en"] = d; it["friction_en"] = fr; it["plain_en"] = pl
    save("pathway_steps.json", pw)

    cl = load("checklist_items.json")
    for it in cl:
        n, o, v, no = CHECKLIST[it["item_id"]]
        it["name_en"] = n; it["origin_en"] = o; it["validity_en"] = v
        if no:
            it["notes_en"] = no
    save("checklist_items.json", cl)

    rf = load("red_flags.json")
    for it in rf:
        s, r, c, n = RED_FLAG[it["flag_id"]]
        it["signal_en"] = s; it["route_en"] = r; it["route_contact_en"] = c; it["never_say_en"] = n
    save("red_flags.json", rf)

    return ["citable_assertions.json", "service_types.json", "glossary.json",
            "service_units.json", "pathway_steps.json", "checklist_items.json",
            "red_flags.json"]
