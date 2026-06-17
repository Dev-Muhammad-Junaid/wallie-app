import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case parents
    case charts
    case labs
    case medications

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .parents: return "Parents"
        case .charts: return "Charts"
        case .labs: return "Labs"
        case .medications: return "Meds"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .parents: return "person.2.fill"
        case .charts: return "chart.xyaxis.line"
        case .labs: return "doc.text.magnifyingglass"
        case .medications: return "pills.fill"
        }
    }
}

struct MainTabView: View {
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @State private var selectedTab: AppTab = .dashboard
    @State private var showQuickLog = false
    @State private var showImportLab = false
    @State private var showSettings = false

    private var selectedParent: ParentProfile? { parents.first }

    var body: some View {
        ZStack(alignment: .bottom) {
            HealthGradientBackground()

            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(onOpenSettings: { showSettings = true })
                case .parents:
                    ParentsListView()
                case .charts:
                    ChartsView()
                case .labs:
                    LabReportsView()
                case .medications:
                    MedicationsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                if selectedTab == .dashboard || selectedTab == .parents || selectedTab == .labs {
                    HStack {
                        Spacer()
                        GlassFAB(icon: "plus") {
                            if selectedTab == .labs {
                                showImportLab = true
                            } else {
                                showQuickLog = true
                            }
                        }
                        .padding(.trailing, 22)
                        .padding(.bottom, 8)
                    }
                }

                customTabBar
            }
        }
        .sheet(isPresented: $showQuickLog) {
            QuickLogView()
        }
        .sheet(isPresented: $showImportLab) {
            if let parent = selectedParent {
                ImportLabReportView(parent: parent)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .preferredColorScheme(.dark)
        .task {
            await NotificationService.shared.refreshAuthorizationStatus()
            if AppSettings.notificationsEnabled, NotificationService.shared.isAuthorized {
                await NotificationService.shared.rescheduleAll(parents: parents)
            }
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .liquidGlass(cornerRadius: 28, interactive: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    MainTabView()
        .modelContainer(SampleData.previewContainer)
}
