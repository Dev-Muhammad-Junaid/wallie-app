import SwiftUI
import SwiftData
import PhotosUI

struct LabReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @State private var selectedParentID: UUID?
    @State private var showImport = false

    private var selectedParent: ParentProfile? {
        if let id = selectedParentID {
            return parents.first { $0.id == id }
        }
        return parents.first
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    parentPicker

                    if let parent = selectedParent {
                        if parent.labReports.isEmpty {
                            emptyState
                        } else {
                            ForEach(parent.labReports.sorted(by: { $0.importedAt > $1.importedAt }), id: \.id) { report in
                                NavigationLink {
                                    LabReportDetailView(report: report)
                                } label: {
                                    LabReportCard(report: report)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        modelContext.delete(report)
                                    }
                                }
                            }
                        }
                    } else {
                        GlassCard {
                            Text("Add a parent profile to import lab reports.")
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .navigationTitle("Lab Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImport = true
                    } label: {
                        Image(systemName: "doc.text.viewfinder")
                    }
                    .disabled(selectedParent == nil)
                }
            }
        }
        .sheet(isPresented: $showImport) {
            if let parent = selectedParent {
                ImportLabReportView(parent: parent)
            }
        }
        .onAppear {
            selectedParentID = parents.first?.id
        }
    }

    private var parentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(parents) { parent in
                    Button {
                        selectedParentID = parent.id
                    } label: {
                        Text(parent.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .liquidGlass(cornerRadius: 16, interactive: true)
                            .opacity(selectedParent?.id == parent.id ? 1 : 0.55)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.softMint)
                Text("No lab reports yet")
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)
                Text("Import a photo of a lab report for on-device OCR and AI-style insights.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                Button("Import Report") { showImport = true }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.deepTeal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
    }
}

struct LabReportCard: View {
    let report: LabReport

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(report.title)
                        .font(.sectionHeadline)
                        .foregroundStyle(.white)
                    Spacer()
                    if report.abnormalCount > 0 {
                        Text("\(report.abnormalCount) flagged")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.warmCoral)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppTheme.warmCoral.opacity(0.2)))
                    }
                }

                Text(report.importedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                Text("\(report.results.count) values extracted")
                    .font(.caption)
                    .foregroundStyle(AppTheme.softMint.opacity(0.9))
            }
        }
    }
}

#Preview {
    LabReportsView()
        .modelContainer(SampleData.previewContainer)
}
