import SwiftUI
import SwiftData

private enum PresentedSheet: String, Identifiable {
    case quickLog
    case importLab
    case addMedication
    case addParent
    case settings
    case healthAlerts

    var id: String { rawValue }
}

struct MainTabView: View {
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @EnvironmentObject private var parentStore: SelectedParentStore
    @EnvironmentObject private var navigationStore: AppNavigationStore
    @Namespace private var tabHighlightNamespace

    @State private var selectedTab: AppTab = .dashboard
    @State private var presentedSheet: PresentedSheet?

    var body: some View {
        ZStack {
            HealthGradientBackground()

            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(
                        onOpenSettings: { presentedSheet = .settings },
                        onOpenCharts: { metric in navigationStore.openCharts(metric: metric) },
                        onOpenAlerts: { presentedSheet = .healthAlerts }
                    )
                case .parents:
                    ParentsListView(showAddParent: Binding(
                        get: { presentedSheet == .addParent },
                        set: { if $0 { presentedSheet = .addParent } else if presentedSheet == .addParent { presentedSheet = nil } }
                    ))
                case .charts:
                    ChartsView()
                case .labs:
                    LabReportsView(showImport: Binding(
                        get: { presentedSheet == .importLab },
                        set: { if $0 { presentedSheet = .importLab } else if presentedSheet == .importLab { presentedSheet = nil } }
                    ))
                case .medications:
                    MedicationsView(showAddMedication: Binding(
                        get: { presentedSheet == .addMedication },
                        set: { if $0 { presentedSheet = .addMedication } else if presentedSheet == .addMedication { presentedSheet = nil } }
                    ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(
                \.bottomChromeScrollPadding,
                AppTheme.BottomChrome.scrollPadding(showsFAB: activeFAB != nil)
            )
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomChrome
        }
        .sheet(item: $presentedSheet) { sheet in
            sheetContent(for: sheet)
        }
        .preferredColorScheme(.dark)
        .onChange(of: navigationStore.requestedTab) { _, tab in
            guard let tab else { return }
            selectTab(tab, animated: true)
            navigationStore.requestedTab = nil
        }
        .onChange(of: navigationStore.showHealthAlerts) { _, show in
            if show {
                presentedSheet = .healthAlerts
                navigationStore.showHealthAlerts = false
            }
        }
        .onChange(of: navigationStore.showAddMedication) { _, show in
            if show {
                presentedSheet = .addMedication
                navigationStore.showAddMedication = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appNavigationRequested)) { notification in
            handleNotificationNavigation(notification)
        }
        .task {
            parentStore.ensureSelection(from: parents)
            await NotificationService.shared.refreshAuthorizationStatus()
            if AppSettings.notificationsEnabled, NotificationService.shared.isAuthorized {
                await NotificationService.shared.rescheduleAll(parents: parents)
            }
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: PresentedSheet) -> some View {
        switch sheet {
        case .quickLog:
            QuickLogView()
                .environmentObject(parentStore)
        case .importLab:
            if let parent = parentStore.parent(from: parents) {
                ImportLabReportView(parent: parent)
            } else {
                Text("Add a parent profile first.")
                    .padding()
            }
        case .addMedication:
            AddMedicationView()
                .environmentObject(parentStore)
        case .addParent:
            ParentFormView()
                .environmentObject(parentStore)
        case .settings:
            SettingsView()
                .environmentObject(parentStore)
        case .healthAlerts:
            HealthAlertsView()
                .environmentObject(parentStore)
        }
    }

    private var bottomChrome: some View {
        VStack(spacing: 8) {
            if let fab = activeFAB {
                HStack {
                    Spacer()
                    GlassFAB(icon: fab.icon, accessibilityLabel: fab.label) {
                        handleFABTap(fab)
                    }
                    .padding(.trailing, 22)
                }
                .zIndex(1)
            }

            customTabBar
        }
        .padding(.bottom, 6)
        .background {
            LinearGradient(
                colors: [AppTheme.midnight.opacity(0), AppTheme.midnight.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
    }

    /// Contextual FAB per tab. Charts is read-only — no FAB.
    private var activeFAB: FABConfig? {
        switch selectedTab {
        case .dashboard:
            return FABConfig(icon: "waveform.path.ecg", label: "Log vitals", action: .logVitals)
        case .parents:
            return FABConfig(icon: "person.badge.plus", label: "Add parent", action: .addParent)
        case .charts:
            return nil
        case .labs:
            return FABConfig(icon: "doc.viewfinder", label: "Import lab report", action: .importLab)
        case .medications:
            return FABConfig(icon: "pills.fill", label: "Add medication", action: .addMedication)
        }
    }

    private func handleFABTap(_ fab: FABConfig) {
        FeedbackService.lightTap()
        switch fab.action {
        case .logVitals:
            presentedSheet = .quickLog
        case .addParent:
            presentedSheet = .addParent
        case .importLab:
            guard parentStore.parent(from: parents) != nil else {
                selectTab(.parents, animated: true)
                presentedSheet = .addParent
                return
            }
            presentedSheet = .importLab
        case .addMedication:
            guard !parents.isEmpty else {
                selectTab(.parents, animated: true)
                presentedSheet = .addParent
                return
            }
            presentedSheet = .addMedication
        }
    }

    private func handleNotificationNavigation(_ notification: Notification) {
        guard let type = notification.userInfo?["type"] as? String else { return }
        switch type {
        case "health_alert":
            presentedSheet = .healthAlerts
        case "medication":
            selectTab(.medications, animated: true)
        case "weekly_summary":
            selectTab(.dashboard, animated: true)
        default:
            break
        }
    }

    private func selectTab(_ tab: AppTab, animated: Bool) {
        guard selectedTab != tab else { return }
        FeedbackService.lightTap()
        if animated {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedTab = tab
            }
        } else {
            selectedTab = tab
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .liquidGlass(cornerRadius: 28, interactive: false)
        .padding(.horizontal, 16)
    }

    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectTab(tab, animated: true)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? AppTheme.tabSelectedForeground : AppTheme.tabUnselectedForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(AppTheme.tabSelectedBackground)
                        .overlay(
                            Capsule()
                                .strokeBorder(AppTheme.tabSelectedBorder, lineWidth: 1)
                        )
                        .matchedGeometryEffect(id: "tabHighlight", in: tabHighlightNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct FABConfig {
    let icon: String
    let label: String
    let action: FABAction
}

private enum FABAction {
    case logVitals
    case addParent
    case importLab
    case addMedication
}

/// Immediate press feedback without delaying the tab action.
private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

#Preview {
    MainTabView()
        .environmentObject(SelectedParentStore())
        .environmentObject(AppNavigationStore())
        .modelContainer(SampleData.previewContainer)
}
