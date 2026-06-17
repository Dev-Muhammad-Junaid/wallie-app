import SwiftUI
import SwiftData
import PhotosUI

/// Fast lab import: photo or paste → preview → one-tap save. No long forms.
struct ImportLabReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let parent: ParentProfile

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var pastedText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var preview: LabAnalysisResult?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    if let preview {
                        previewSection(preview)
                    } else {
                        inputSection
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(AppTheme.warmCoral)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(20)
            }
            .background(HealthGradientBackground())
            .navigationTitle("Add Lab Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if preview != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { savePreview() }
                    }
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView("Analyzing…")
                        .padding(20)
                        .liquidGlass(cornerRadius: 16)
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Quick import for \(parent.name)",
                subtitle: "Snap a photo or paste text — we'll extract values automatically"
            )

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                GlassCard {
                    HStack(spacing: 14) {
                        Image(systemName: "camera.viewfinder")
                            .font(.title2)
                            .foregroundStyle(AppTheme.softMint)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Take or choose photo")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("On-device OCR — nothing leaves your phone")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task { await loadAndAnalyzePhoto(item) }
            }

            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Or paste report text")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    TextField("Glucose: 110 mg/dL, HbA1c: 5.8%…", text: $pastedText, axis: .vertical)
                        .lineLimit(3...8)
                        .foregroundStyle(.white)
                }
            }

            QuickSaveBar(title: "Analyze", isEnabled: canAnalyze && !isProcessing) {
                Task { await analyzeText() }
            }
        }
    }

    private func previewSection(_ result: LabAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("AI Insights", systemImage: "sparkles")
                            .font(.sectionHeadline)
                            .foregroundStyle(AppTheme.softMint)
                        Spacer()
                        Text(result.providerName)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    Text(result.insights)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        title: "\(result.results.count) values found",
                        subtitle: result.labDate.map { "Lab date: \($0.formatted(date: .abbreviated, time: .omitted))" }
                    )
                    ForEach(result.results, id: \.testKey) { item in
                        HStack {
                            Text(item.testName)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(format(item.value)) \(item.unit)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(item.isAbnormal ? AppTheme.warmCoral : .white)
                        }
                    }
                }
            }

            QuickSaveBar(title: "Save to \(parent.name)'s records", isEnabled: true) {
                savePreview()
            }

            Button("Re-analyze") {
                preview = nil
                errorMessage = nil
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.55))
            .frame(maxWidth: .infinity)
        }
    }

    private var canAnalyze: Bool {
        selectedImage != nil || !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadAndAnalyzePhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        selectedImage = image
        await analyze(image: image)
    }

    private func analyzeText() async {
        let text = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }
        do {
            preview = try await LabAnalysisService.provider().analyze(text: text, parentName: parent.name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func analyze(image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }
        do {
            preview = try await LabAnalysisService.provider().analyze(image: image, parentName: parent.name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func savePreview() {
        guard let preview else { return }
        let report = LabReportRepository.save(analysis: preview, parent: parent, title: nil, context: modelContext)
        let alerts = HealthAlertService.labAlerts(from: preview, parent: parent, reportID: report.id)
        if !alerts.isEmpty {
            Task {
                await NotificationService.shared.notifyHealthAlerts(alerts)
            }
        }
        dismiss()
    }

    private func format(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value))" }
        return String(format: "%.1f", value)
    }
}

#Preview {
    ImportLabReportView(parent: SampleData.previewParent)
        .modelContainer(SampleData.previewContainer)
}
