import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var page = 0

    private let pages = OnboardingPage.all

    var body: some View {
        ZStack {
            HealthGradientBackground()

            VStack(spacing: 0) {
                HStack {
                    Text("ParentsHealth")
                        .font(.captionMuted)
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    if page < pages.count - 1 {
                        Button("Skip") {
                            FeedbackService.lightTap()
                            finish()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.softMint)
                        .accessibilityIdentifier("onboardingSkip")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingPageView(page: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.35, dampingFraction: 0.86), value: page)

                VStack(spacing: 18) {
                    pageIndicator

                    if page == pages.count - 1 {
                        QuickSaveBar(title: "Get started", isEnabled: true) {
                            FeedbackService.success()
                            finish()
                        }
                        .accessibilityIdentifier("onboardingGetStarted")
                    } else {
                        QuickSaveBar(title: "Continue", isEnabled: true) {
                            FeedbackService.lightTap()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                page += 1
                            }
                        }
                        .accessibilityIdentifier("onboardingContinue")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == page ? AppTheme.softMint : Color.white.opacity(0.22))
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page + 1) of \(pages.count)")
    }

    private func finish() {
        AppSettings.hasCompletedOnboarding = true
        onFinished()
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(page.accent.opacity(0.18))
                        .frame(width: 108, height: 108)
                        .blur(radius: 2)
                    Image(systemName: page.icon)
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(page.accent)
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    Text(page.eyebrow)
                        .font(.captionMuted)
                        .foregroundStyle(.white.opacity(0.55))
                    Text(page.title)
                        .font(.displayTitle)
                        .foregroundStyle(.white)
                    Text(page.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    ForEach(page.points) { point in
                        GlassCard(padding: 14) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: point.icon)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(page.accent)
                                    .frame(width: 28, height: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(point.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(point.detail)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.55))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let points: [OnboardingPoint]

    static let all: [OnboardingPage] = [
        OnboardingPage(
            eyebrow: "Welcome",
            title: "Care, kept close.",
            subtitle: "ParentsHealth helps you track your parents’ health in one private place — on this device.",
            icon: "heart.text.clipboard.fill",
            accent: AppTheme.softMint,
            points: [
                OnboardingPoint(icon: "person.2.fill", title: "Two parents, one home", detail: "Switch profiles with the chips you already see on Home."),
                OnboardingPoint(icon: "lock.shield.fill", title: "Private by default", detail: "Vitals, labs, and meds stay on-device. No analytics.")
            ]
        ),
        OnboardingPage(
            eyebrow: "Daily care",
            title: "Meds, logged simply.",
            subtitle: "Morning and evening slots, plus weekly or monthly schedules when a pill isn’t every day.",
            icon: "pills.fill",
            accent: AppTheme.warmCoral,
            points: [
                OnboardingPoint(icon: "checkmark.circle.fill", title: "Taken, Skip, Undo", detail: "Log today’s dose in one tap from the Meds tab."),
                OnboardingPoint(icon: "text.viewfinder", title: "Scan a label", detail: "Photo a bottle to fill name and dosage — then review before save.")
            ]
        ),
        OnboardingPage(
            eyebrow: "Records",
            title: "Labs and vitals, per parent.",
            subtitle: "Import a report photo, log blood pressure, and watch trends without mixing profiles.",
            icon: "doc.viewfinder",
            accent: AppTheme.metricWeight,
            points: [
                OnboardingPoint(icon: "chart.xyaxis.line", title: "Charts that jump to data", detail: "Lab Trends and BP stats live in the Charts tab."),
                OnboardingPoint(icon: "bell.badge.fill", title: "Out-of-range alerts", detail: "Home shows what needs a closer look — not medical advice.")
            ]
        ),
        OnboardingPage(
            eyebrow: "Care network",
            title: "Doctors and visits.",
            subtitle: "Save who to call and when the next appointment is, so nothing lives only in a notebook.",
            icon: "stethoscope",
            accent: AppTheme.softMint,
            points: [
                OnboardingPoint(icon: "phone.fill", title: "Contacts in one tap", detail: "Name, specialty, clinic, and call or email from Care Network."),
                OnboardingPoint(icon: "waveform", title: "Siri on every iPhone we support", detail: "Say Log a dose in ParentsHealth with classic Siri on iOS 17. Newer iOS can also use Apple Intelligence — names stay out of Search until you allow it in Settings."),
                OnboardingPoint(icon: "calendar", title: "Visit reminders", detail: "Pick a date and get a local reminder before you go.")
            ]
        )
    ]
}

private struct OnboardingPoint: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
}

#Preview {
    OnboardingView(onFinished: {})
}
