# ParentsHealth

A native iOS caregiver app for tracking a parent’s health in one private place — vitals, medications, lab reports, doctor visits, and alerts. Built with SwiftUI and SwiftData. Data stays on-device unless you turn on optional iCloud sync.

**Not medical advice.** The app records what you log and flags values outside common reference ranges. It does not diagnose, treat, or replace a clinician.

## Features

- **Parent profiles** — Multiple parents, conditions, blood type, emergency contacts
- **Vitals** — Blood pressure, weight, heart rate, glucose, with optional HealthKit import
- **Charts** — Monthly vitals and lab trends, including BP systolic/diastolic stats
- **Medications** — Daily, twice daily, weekly, monthly, and as-needed schedules; Taken / Skip / Undo per slot; local reminders; weekly adherence
- **Label scan** — Camera or photo OCR to prefill medication name and dosage
- **Labs** — On-device OCR and parsing, per-parent history, deltas vs the last report, optional remote API
- **Care network** — Doctors (call / email) and appointments with visit reminders
- **Health score & alerts** — Composite score plus out-of-range vitals and labs (informational only)
- **Siri & Shortcuts** — Log a dose, ask what’s due today, next appointment, log BP, call a doctor — on iOS 17+ without Apple Intelligence
- **Export** — Share a text health snapshot
- **Onboarding** — First-run tour; replay from Settings

## What’s cooking

Shipped next, in roughly this order. Nothing here is medical advice.

- **Siri on a real device** — Exercise Shortcuts, Action Button, and “What’s due today” on the iPad build, then tighten phrases that feel awkward in classic Siri.
- **CloudKit family sync** — Restore the iCloud container on a paid team so two devices on the same Apple ID actually share parents, meds, labs, and visits. Today the toggle exists; personal-team installs stay on-device.
- **Siblings on different Apple IDs** — Shared care data without forcing one iCloud login. Not started.
- **Apple Intelligence, when the phone has it** — Visual Intelligence for bottle / lab photos, on-device Foundation Models for a short lab recap you can edit, and App Schema / on-screen “this” so newer Siri can act on what’s visible. iOS 17 keeps working without any of that.
- **Widgets** — Today’s pending doses and next appointment on the Home Screen, using the same App Intents.
- **Calendar handoff** — Optionally write visits into EventKit so they show up in Calendar. The in-app Care Network remains the source of truth.

Intentionally not cooking: long-term “is this med in a healthy zone?” education. Too easy to read as treatment advice.

## Requirements

| | |
| --- | --- |
| Xcode | 16 or later |
| iOS | 17.0 or later (iPhone and iPad) |
| Signing | Your Apple Development team in Xcode |
| SwiftData | Required — this is why the floor is iOS 17, not 16 |

Liquid Glass styling uses `.glassEffect()` on newer iOS and falls back to materials on iOS 17–25.

Apple Intelligence / Siri AI extras (semantic Spotlight) need iOS 18+ and an opt-in in **Settings → Siri & Spotlight**. Classic Siri phrases and the Shortcuts app work on every supported iOS version. Labs, vitals, and notes are never indexed.

## Getting started

1. Clone the repo and open `ParentsHealth.xcodeproj`.
2. Select your development team under **Signing & Capabilities**.
3. Build and run on a simulator or device (⌘R).

First launch seeds Margaret & Robert Chen so Home, Charts, Labs, and Meds have something to show. **Settings → Load 1-Year Sample Data** replaces all profiles with a fuller demo year.

### Optional capabilities

- **HealthKit** — already in the entitlements. Grant access in Settings or the Health app.
- **iCloud Sync** — off by default. Personal-team installs may not include a CloudKit container; the app still runs on-device. A paid team plus the iCloud capability (`iCloud.com.widgetsflow.parentshealth`) is required for multi-device sync on the same Apple ID.
- **Notifications** — medication reminders, appointment reminders, out-of-range alerts, weekly summary.

## Siri, Shortcuts, and Spotlight

App Intents live in `ParentsHealth/Intents/`. Useful phrases (include the app name):

- “Log a dose in ParentsHealth”
- “What’s due today in ParentsHealth”
- “Next appointment in ParentsHealth”
- “Log blood pressure in ParentsHealth”
- “Call the doctor in ParentsHealth”

You can also run the same actions from the Shortcuts app or the Action Button. Deep links use the `parentshealth://` scheme (`parent`, `meds`, `labs`, `care`, `charts`, `alerts`).

**Settings → Index names in Spotlight** is off by default. When on, only parent names, medication names, and visit titles are donated — never lab values or vitals.

## Lab reports

```
Photo or paste → on-device OCR + parse → preview → save → Charts
```

On-device analysis is the default. In **Settings → Lab Report AI** you can point at your own API; the app falls back to local parsing if the server is down.

Expected JSON:

```json
{
  "results": [
    {
      "testKey": "glucose",
      "testName": "Glucose",
      "value": 110,
      "unit": "mg/dL",
      "referenceRange": "70–100",
      "isAbnormal": false
    }
  ],
  "labDate": "2026-03-15T00:00:00Z",
  "insights": "Optional summary text"
}
```

Canonical keys include glucose, HbA1c, lipids, and common CBC/CMP markers (`LabTestKey`).

## Privacy

- SwiftData on device by default. No analytics.
- Lab and medication OCR run on-device.
- HealthKit is read-only import you turn on.
- iCloud sync is optional and only shares with other devices on the **same** Apple ID. Different Apple IDs (for example two siblings) do not share a database yet.
- Siri shortcuts work without Search indexing. Spotlight is opt-in and name-only.

## Project structure

```
ParentsHealth/
├── App/           Entry point, persistence, app delegate
├── Models/        SwiftData: parents, vitals, meds, labs, doctors, appointments
├── Design/        Theme and Liquid Glass components
├── Views/         Home, Parents, Charts, Labs, Meds, Care, Settings, Onboarding
├── Services/      HealthKit, notifications, OCR, alerts, export, Siri helpers
└── Intents/       App Intents, entities, and App Shortcuts

ParentsHealthTests/     Unit tests
ParentsHealthUITests/   Launch and tab UI tests
scripts/                Xcode project generator and offline logic checks
```

## Testing

```bash
xcodebuild test \
  -project ParentsHealth.xcodeproj \
  -scheme ParentsHealth \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO
```

- **Unit tests** — health score, lab parser, metric ranges, med schedules, adherence, OCR helpers, export, alerts, Siri care actions, deep links
- **UI tests** — launch with `UI_TESTING` (skips onboarding, seeds demo data), tab navigation, settings

Without Xcode:

```bash
python3 scripts/validate_logic.py
```

After adding Swift files, regenerate the Xcode project with `python3 scripts/gen_pbxproj.py`.

## Design

Midnight / deep teal / soft mint / warm coral. Glass cards over a health gradient, shared parent chips, and a floating tab bar. Liquid Glass on newer iOS; the same layout on iOS 17.

## License

MIT
