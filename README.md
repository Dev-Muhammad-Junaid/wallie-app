# ParentsHealth

A private iOS app to track your parents' health — vitals, medications, doctor visits, lab reports, and health scores. Built with native SwiftUI and Apple's Liquid Glass design language.

## Features

- **Parent Profiles** — manage multiple parents with conditions, blood type, emergency contacts
- **Daily Vitals** — log blood pressure, weight, heart rate, and blood glucose
- **Monthly Charts** — Swift Charts trends with month navigation and min/avg/max stats
- **Medication Tracking** — daily / weekly / monthly / as-needed schedules, Taken/Skip/Undo, local reminders, adherence
- **Medication Label Scan** — photo or camera OCR to prefill name and dosage
- **Care Network** — save doctors (phone/email) and appointments with visit reminders
- **Lab Report Analysis** — on-device OCR (Vision) + value extraction + AI-style insights
- **HealthKit Sync** — optional import of BP, weight, HR, glucose from Apple Health
- **iCloud Sync** — optional SwiftData CloudKit sync across devices on the same iCloud account
- **Export Reports** — share text health summaries
- **Health Score** — composite score from recent vitals
- **Health Alerts** — out-of-range vitals and lab markers with severity, boundary analysis, trend direction, and plain-language health impact notes
- **Liquid Glass UI** — `.glassEffect()` on iOS 26+ with material fallback on iOS 17–25

## Requirements

- Xcode 16+
- iOS 17.0+ (Liquid Glass effects on iOS 26+)
- macOS for building and running

## Getting Started

1. Clone the repository
2. Open `ParentsHealth.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Enable the **iCloud** capability with CloudKit (container `iCloud.com.widgetsflow.parentshealth`) if you want multi-device sync
5. Build and run on simulator or device (⌘R)

Sample data (Margaret & Robert Chen) is seeded automatically on first launch.

## Lab Reports — How It Works

Each parent has their own lab report history:

```
Photo or paste → OCR + AI parse → Preview → Save → Charts
```

1. **Import** — Labs tab → `+` → snap photo or paste text (no long forms)
2. **Analyze** — On-device by default (`LocalLabAnalysisProvider`). Optional API in Settings.
3. **Save** — Values stored with canonical `LabTestKey` (glucose, hba1c, LDL, etc.)
4. **Charts** — Charts tab → **Lab Trends** → line chart across all saved reports
5. **Compare** — Report detail shows delta vs previous visit

### Future AI API

In **Settings → Lab Report AI**, add your endpoint. Expected JSON:

```json
{
  "results": [{ "testKey": "glucose", "testName": "Glucose", "value": 110, "unit": "mg/dL", "referenceRange": "70–100", "isAbnormal": false }],
  "labDate": "2026-03-15T00:00:00Z",
  "insights": "Optional summary text"
}
```

Falls back to on-device parsing if API is unavailable.

## Quick Entry UX

- **Vitals** — tap metric chip → enter number → Save (2 taps + typing)
- **Labs** — photo or paste → Analyze → Save (no title required)
- **Parent chips** — shared across Labs, Charts, Quick Log

## Health Alerts

The app surfaces **out-of-range indicators** so you can see what needs attention without digging through every log:

1. **Home** — bell icon (badge count) and **Health Alerts** card with top priorities
2. **Alerts screen** — filter by vitals vs labs; each card shows:
   - Value vs reference range (above/below boundary)
   - Severity: Watch · Needs attention · Priority
   - Trend for labs (improving / worsening / stable)
   - **What this can affect** — educational notes on possible body/health impact
   - Suggested next step (informational, not medical advice)
3. **Notifications** — optional push when a new vital or lab save is out of range (Settings → Out-of-Range Health Alerts)

Vitals use the last 7 days; labs use the latest result per test key from saved reports.

## Testing

### Xcode (full suite)

```bash
xcodebuild test \
  -project ParentsHealth.xcodeproj \
  -scheme ParentsHealth \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO
```

**Unit tests** (`ParentsHealthTests`): health score, lab parser, metric ranges, adherence, export, health alerts  
**UI tests** (`ParentsHealthUITests`): tab navigation, settings, core screens

### Offline logic validation (no Xcode)

```bash
python3 scripts/validate_logic.py
```

## Project Structure

```
ParentsHealth/
├── App/              Entry point, app delegate
├── Models/           SwiftData models (profiles, metrics, meds, labs)
├── Design/           Liquid Glass components & theme
├── Views/            Dashboard, Parents, Charts, Labs, Meds, Settings
└── Services/         Notifications, HealthKit, OCR, parsers, export

ParentsHealthTests/   Unit tests
ParentsHealthUITests/ UI tests
scripts/              Offline logic validation
```

## Privacy

Health data is stored with SwiftData. Lab and medication OCR/analysis run on-device. Optional **iCloud Sync** (Settings) keeps the same Apple ID’s devices in sync via CloudKit — siblings using different Apple IDs do not share a database yet. No analytics.

## Linear Project

Track development in [ParentsHealth on Linear](https://linear.app/widgetsflow/project/parentshealth-e6951c4d67ce).

## Design

Inspired by Apple's Liquid Glass (WWDC25) and Hallmark anti-slop layout principles — asymmetric bento dashboard, distinctive teal/coral palette, glass functional layer over rich gradient backgrounds.

## License

MIT
