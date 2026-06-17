import SwiftUI
import SwiftData

struct QuickLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]

    @State private var selectedParentID: UUID?
    @State private var selectedType: MetricType = .bloodPressure
    @State private var valueText = ""
    @State private var secondaryValueText = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Parent") {
                    Picker("Parent", selection: $selectedParentID) {
                        ForEach(parents) { parent in
                            Text(parent.name).tag(Optional(parent.id))
                        }
                    }
                }

                Section("Metric") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(MetricType.allCases) { type in
                            Label(type.title, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    if selectedType == .bloodPressure {
                        TextField("Systolic", text: $valueText)
                            .keyboardType(.numberPad)
                        TextField("Diastolic", text: $secondaryValueText)
                            .keyboardType(.numberPad)
                    } else {
                        TextField("Value (\(selectedType.unit))", text: $valueText)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let value = Double(valueText), !valueText.isEmpty {
                    Section {
                        HStack {
                            Text("Status")
                            Spacer()
                            let secondary = Double(secondaryValueText)
                            let normal = selectedType.isNormal(value: value, secondaryValue: secondary)
                            Text(normal ? "Normal" : "Out of range")
                                .foregroundStyle(normal ? .green : .orange)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("Log Vitals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                selectedParentID = parents.first?.id
            }
        }
    }

    private var canSave: Bool {
        guard selectedParentID != nil, let value = Double(valueText) else { return false }
        if selectedType == .bloodPressure {
            return Double(secondaryValueText) != nil && value > 0
        }
        return value > 0
    }

    private func save() {
        guard let parent = parents.first(where: { $0.id == selectedParentID }),
              let value = Double(valueText) else { return }

        let secondary = Double(secondaryValueText)
        let metric = HealthMetric(
            type: selectedType,
            value: value,
            secondaryValue: secondary,
            notes: notes,
            parent: parent
        )
        modelContext.insert(metric)
        dismiss()
    }
}

#Preview {
    QuickLogView()
        .modelContainer(SampleData.previewContainer)
}
