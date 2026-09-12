import SwiftUI
import SwiftData

struct ParentsListView: View {
    @Binding var showAddParent: Bool

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var parentStore: SelectedParentStore
    @EnvironmentObject private var navigationStore: AppNavigationStore
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @State private var parentToEdit: ParentProfile?
    @State private var parentToDelete: ParentProfile?
    @State private var showCareNetwork = false
    @State private var detailParentID: UUID?

    init(showAddParent: Binding<Bool> = .constant(false)) {
        _showAddParent = showAddParent
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if parents.isEmpty {
                    GlassCard {
                        VStack(spacing: 14) {
                            Image(systemName: "person.2.badge.plus")
                                .font(.largeTitle)
                                .foregroundStyle(AppTheme.softMint)
                            Text("No parents yet")
                                .font(.sectionHeadline)
                                .foregroundStyle(.white)
                            Text("Create a profile to start tracking vitals, labs, and medications.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                            Button("Add first parent") { showAddParent = true }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.deepTeal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                } else {
                    LazyVStack(spacing: 14) {
                        Button {
                            FeedbackService.lightTap()
                            showCareNetwork = true
                        } label: {
                            GlassCard(padding: 14) {
                                HStack(spacing: 12) {
                                    Image(systemName: "stethoscope")
                                        .font(.title3)
                                        .foregroundStyle(AppTheme.softMint)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Care Network")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text("Doctors, contacts, and appointments")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        ForEach(parents) { parent in
                            NavigationLink {
                                ParentDetailView(parent: parent)
                            } label: {
                                ParentCard(parent: parent)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Edit") { parentToEdit = parent }
                                Button("Delete", role: .destructive) { parentToDelete = parent }
                            }
                        }

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .scrollBottomClearance()
            .navigationTitle("Parents")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $detailParentID) { id in
                if let parent = parents.first(where: { $0.id == id }) {
                    ParentDetailView(parent: parent)
                }
            }
        }
        .sheet(isPresented: $showCareNetwork) {
            CareProvidersView()
                .environmentObject(parentStore)
        }
        .sheet(item: $parentToEdit) { parent in
            ParentFormView(parent: parent)
                .environmentObject(parentStore)
        }
        .alert("Delete parent?", isPresented: Binding(
            get: { parentToDelete != nil },
            set: { if !$0 { parentToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let parent = parentToDelete {
                    confirmDelete(parent)
                }
                parentToDelete = nil
            }
            Button("Cancel", role: .cancel) { parentToDelete = nil }
        } message: {
            Text("This permanently removes all vitals, medications, and lab reports for this parent.")
        }
        .onAppear {
            parentStore.ensureSelection(from: parents)
            consumeParentDetailRequest()
        }
        .onChange(of: navigationStore.requestedParentDetailID) { _, _ in
            consumeParentDetailRequest()
        }
    }

    private func consumeParentDetailRequest() {
        guard let id = navigationStore.requestedParentDetailID else { return }
        parentStore.parentID = id
        detailParentID = id
        navigationStore.requestedParentDetailID = nil
    }

    private func confirmDelete(_ parent: ParentProfile) {
        Task {
            await NotificationService.shared.cancelMedicationReminders(for: parent.medications)
            for appointment in parent.appointments {
                await NotificationService.shared.cancelAppointmentReminder(for: appointment)
            }
        }
        modelContext.delete(parent)
        parentStore.ensureSelection(from: parents.filter { $0.id != parent.id })
        FeedbackService.warning()
    }
}

struct ParentCard: View {
    let parent: ParentProfile

    var body: some View {
        HStack(spacing: 16) {
            ParentAvatar(initials: parent.initials, hue: parent.avatarHue, size: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(parent.name)
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)
                HStack(spacing: 12) {
                    Label("\(parent.age) yrs", systemImage: "calendar")
                    Label(parent.bloodType, systemImage: "drop.fill")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))

                if !parent.conditions.isEmpty {
                    Text(parent.conditions.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.softMint.opacity(0.9))
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Text("\(parent.healthScore())")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Text("score")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(16)
        .liquidGlass()
    }
}

#Preview {
    ParentsListView()
        .environmentObject(SelectedParentStore())
        .environmentObject(AppNavigationStore())
        .modelContainer(SampleData.previewContainer)
}
