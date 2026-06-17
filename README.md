# ParentsHealth

A private, on-device iOS app to track your parents' health — vitals, medications, monthly trends, and health scores. Built with native SwiftUI and Apple's Liquid Glass design language.

## Features

- **Parent Profiles** — manage multiple parents with conditions, blood type, emergency contacts
- **Daily Vitals** — log blood pressure, weight, heart rate, and blood glucose
- **Monthly Charts** — Swift Charts trends with month navigation and min/avg/max stats
- **Medication Tracking** — schedules, adherence percentage, taken/skipped logging
- **Health Score** — composite score from recent vitals
- **Liquid Glass UI** — `.glassEffect()` on iOS 26+ with material fallback on iOS 17–25

## Requirements

- Xcode 16+
- iOS 17.0+ (Liquid Glass effects on iOS 26+)
- macOS for building and running

## Getting Started

1. Clone the repository
2. Open `ParentsHealth.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on simulator or device (⌘R)

Sample data (Margaret & Robert Chen) is seeded automatically on first launch.

## Project Structure

```
ParentsHealth/
├── App/              App entry point
├── Models/           SwiftData models
├── Design/           Liquid Glass components & theme
├── Views/            Dashboard, Parents, Charts, Medications, Log
└── Services/         Sample data seeder
```

## Privacy

All health data is stored locally on-device using SwiftData. No cloud sync, no analytics, no data sharing.

## Linear Project

Track development in [ParentsHealth on Linear](https://linear.app/widgetsflow/project/parentshealth-e6951c4d67ce).

## Design

Inspired by Apple's Liquid Glass (WWDC25) and Hallmark anti-slop layout principles — asymmetric bento dashboard, distinctive teal/coral palette, glass functional layer over rich gradient backgrounds.

## License

MIT
