import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Fast lab import: photo or paste → preview → one-tap save. No long forms.
struct ImportLabReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let parent: ParentProfile

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var pastedText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var preview: LabAnalysisResult?
    @State private var saveConfirmation: SaveConfirmation?

    private struct SaveConfirmation: Identifiable {
        let id = UUID()
        let valueCount: Int
        let parentName: String
    }

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

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
            }
            .overlay {
                if isProcessing {
                    ProgressView("Analyzing…")
                        .padding(20)
                        .liquidGlass(cornerRadius: 16)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraImagePicker { image in
                    selectedImage = image
                    Task { await analyze(image: image) }
                }
                .ignoresSafeArea()
            }
            .alert("Import saved", isPresented: Binding(
                get: { saveConfirmation != nil },
                set: { if !$0 { saveConfirmation = nil; dismiss() } }
            )) {
                Button("View Labs") {
                    saveConfirmation = nil
                    dismiss()
                }
            } message: {
                if let saveConfirmation {
                    Text("\(saveConfirmation.valueCount) values saved for \(saveConfirmation.parentName). Open the Labs tab to see the report, or Charts → Lab Trends for trends.")
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Quick import for \(parent.name)",
                subtitle: "Take a photo, choose from library, or paste text — we'll extract values automatically"
            )

            HStack(spacing: 12) {
                if isCameraAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        importOptionCard(
                            icon: "camera.fill",
                            title: "Take photo",
                            subtitle: "Use camera"
                        )
                    }
                    .buttonStyle(.plain)
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    importOptionCard(
                        icon: "photo.on.rectangle",
                        title: "Choose photo",
                        subtitle: "From library"
                    )
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

            QuickSaveBar(title: "Save to \(parent.name)'s records", isEnabled: !result.results.isEmpty) {
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

    private func importOptionCard(icon: String, title: String, subtitle: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.softMint)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        guard let preview, !preview.results.isEmpty else {
            errorMessage = "No lab values to save. Re-analyze with a clearer photo or paste text."
            return
        }
        let report = LabReportRepository.save(analysis: preview, parent: parent, title: nil, context: modelContext)
        try? modelContext.save()
        let alerts = HealthAlertService.labAlerts(from: preview, parent: parent, reportID: report.id)
        if !alerts.isEmpty {
            Task {
                await NotificationService.shared.notifyHealthAlerts(alerts)
            }
        }
        FeedbackService.success()
        saveConfirmation = SaveConfirmation(valueCount: preview.results.count, parentName: parent.name)
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
