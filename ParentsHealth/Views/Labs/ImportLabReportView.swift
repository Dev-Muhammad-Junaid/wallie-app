import SwiftUI
import SwiftData
import PhotosUI

struct ImportLabReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let parent: ParentProfile

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var manualText = ""
    @State private var title = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Report") {
                    TextField("Title (e.g. Annual Panel)", text: $title)
                }

                Section("Import from Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(selectedImage == nil ? "Choose Lab Report Photo" : "Change Photo", systemImage: "camera.viewfinder")
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task { await loadImage(from: newItem) }
                    }

                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Section("Or Paste Text") {
                    TextField("Paste lab report text", text: $manualText, axis: .vertical)
                        .lineLimit(4...10)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Import Lab Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Analyze") {
                        Task { await analyzeAndSave() }
                    }
                    .disabled(isProcessing || !canAnalyze)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView("Analyzing on device…")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var canAnalyze: Bool {
        selectedImage != nil || !manualText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        selectedImage = image
    }

    private func analyzeAndSave() async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            var rawText = manualText.trimmingCharacters(in: .whitespacesAndNewlines)
            if let selectedImage, rawText.isEmpty {
                rawText = try await LabReportOCRService.recognizeText(from: selectedImage)
            }

            guard !rawText.isEmpty else {
                errorMessage = "No text found. Try a clearer photo or paste text manually."
                return
            }

            let parsed = LabReportParser.parse(text: rawText)
            let labDate = LabReportParser.extractLabDate(from: rawText)
            let insight = LabReportParser.generateInsights(results: parsed, parentName: parent.name)
            let reportTitle = title.isEmpty
                ? "Lab Report \(Date().formatted(date: .abbreviated, time: .omitted))"
                : title

            let report = LabReport(
                title: reportTitle,
                rawText: rawText,
                labDate: labDate,
                summaryInsight: insight,
                parent: parent
            )
            modelContext.insert(report)

            for parsedResult in parsed {
                let result = LabResult(
                    testName: parsedResult.testName,
                    value: parsedResult.value,
                    unit: parsedResult.unit,
                    referenceRange: parsedResult.referenceRange,
                    isAbnormal: parsedResult.isAbnormal,
                    labReport: report
                )
                modelContext.insert(result)
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ImportLabReportView(parent: SampleData.previewParent)
        .modelContainer(SampleData.previewContainer)
}
