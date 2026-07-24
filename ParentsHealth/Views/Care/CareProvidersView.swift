import SwiftUI
import SwiftData

struct CareProvidersView: View {
    @EnvironmentObject private var parentStore: SelectedParentStore
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @State private var showAddProvider = false
    @State private var providerToEdit: CareProvider?
    @State private var showAddAppointment = false
    @State private var appointmentToEdit: Appointment?

    private var selectedParent: ParentProfile? {
        parentStore.parent(from: parents)
    }

    private var providers: [CareProvider] {
        (selectedParent?.careProviders ?? []).sorted { $0.name < $1.name }
    }

    private var upcoming: [Appointment] {
        selectedParent?.upcomingAppointments ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    ParentChipPicker(parents: parents, selectedParentID: $parentStore.parentID)

                    if parents.isEmpty {
                        emptyParentsCard
                    } else {
                        appointmentsSection
                        providersSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .scrollBottomClearance()
            }
            .background(HealthGradientBackground())
            .navigationTitle("Care Network")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Add doctor", systemImage: "stethoscope") {
                            showAddProvider = true
                        }
                        Button("Add appointment", systemImage: "calendar.badge.plus") {
                            showAddAppointment = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.softMint)
                    }
                    .disabled(selectedParent == nil)
                }
            }
        }
        .sheet(isPresented: $showAddProvider) {
            if let parent = selectedParent {
                AddCareProviderView(parent: parent)
            }
        }
        .sheet(item: $providerToEdit) { provider in
            AddCareProviderView(parent: provider.parent ?? selectedParent!, provider: provider)
        }
        .sheet(isPresented: $showAddAppointment) {
            if let parent = selectedParent {
                AddAppointmentView(parent: parent)
            }
        }
        .sheet(item: $appointmentToEdit) { appointment in
            AddAppointmentView(parent: appointment.parent ?? selectedParent!, appointment: appointment)
        }
        .onAppear {
            parentStore.ensureSelection(from: parents)
        }
    }

    private var emptyParentsCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "person.2.badge.plus")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.softMint)
                Text("Add a parent first")
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)
                Text("Doctors and appointments are tracked per parent.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Upcoming appointments", subtitle: "Reminders fire before each visit")

            if upcoming.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No upcoming visits")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Schedule the next doctor visit so you don’t forget.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        Button("Add appointment") { showAddAppointment = true }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.deepTeal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(upcoming, id: \.id) { appointment in
                    AppointmentCard(appointment: appointment) {
                        appointmentToEdit = appointment
                    }
                }
            }
        }
    }

    private var providersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Doctors & contacts", subtitle: "Tap call to dial instantly")

            if providers.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No doctors saved")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Save specialists and clinics so siblings can find them quickly.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        Button("Add doctor") { showAddProvider = true }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.deepTeal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(providers, id: \.id) { provider in
                    CareProviderCard(provider: provider) {
                        providerToEdit = provider
                    }
                }
            }
        }
    }
}

struct AppointmentCard: View {
    let appointment: Appointment
    var onEdit: (() -> Void)?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.displayTitle)
                            .font(.sectionHeadline)
                            .foregroundStyle(.white)
                        Text(appointment.providerName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    if let onEdit {
                        Button("Edit", action: onEdit)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.softMint)
                    }
                }

                Label(
                    appointment.scheduledAt.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "calendar"
                )
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

                if !appointment.location.isEmpty {
                    Label(appointment.location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
    }
}

struct CareProviderCard: View {
    let provider: CareProvider
    var onEdit: (() -> Void)?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider.name)
                            .font(.sectionHeadline)
                            .foregroundStyle(.white)
                        Text(provider.displaySpecialty)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    if let onEdit {
                        Button("Edit", action: onEdit)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.softMint)
                    }
                }

                if !provider.clinic.isEmpty {
                    Text(provider.clinic)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                HStack(spacing: 10) {
                    if let url = provider.phoneURL {
                        Link(destination: url) {
                            Label(provider.phone.isEmpty ? "Call" : provider.phone, systemImage: "phone.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AppTheme.softMint.opacity(0.35))
                                )
                        }
                    }

                    if let email = emailURL {
                        Link(destination: email) {
                            Label("Email", systemImage: "envelope.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AppTheme.deepTeal.opacity(0.45))
                                )
                        }
                    }
                }
            }
        }
    }

    private var emailURL: URL? {
        let trimmed = provider.email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: "mailto:\(trimmed)")
    }
}

#Preview {
    CareProvidersView()
        .environmentObject(SelectedParentStore())
        .modelContainer(SampleData.previewContainer)
}
