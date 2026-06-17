import SwiftUI
import SwiftData

/// Minimal vitals entry — pick parent, tap metric, enter value, save. No long forms.
struct QuickLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var parentStore: SelectedParentStore
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]

    @State private var selectedType: MetricType = .bloodPressure
    @State private var valueText = ""
    @State private var secondaryValueText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    SectionHeader(title: "Log vitals", subtitle: "Tap a metric, enter the number, save — done.")

                    ParentChipPicker(parents: parents, selectedParentID: $parentStore.parentID)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(MetricType.allCases) { type in
                            Button {
                                withAnimation(.spring(response: 0.25)) {
                                    selectedType = type
                                    valueText = ""
                                    secondaryValueText = ""
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                        .font(.title3)
                                    Text(type.title)
                                        .font(.caption.weight(.semibold))
                                        .multilineTextAlignment(.center)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(selectedType == type
                                              ? AppTheme.metricColor(for: type).opacity(0.45)
                                              : Color.white.opacity(0.08))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(selectedType.title)
                                .font(.sectionHeadline)
                                .foregroundStyle(.white)

                            if selectedType == .bloodPressure {
                                HStack(spacing: 12) {
                                    valueField("Systolic", text: $valueText)
                                    Text("/").foregroundStyle(.white.opacity(0.4))
                                    valueField("Diastolic", text: $secondaryValueText)
                                }
                            } else {
                                valueField("Value (\(selectedType.unit))", text: $valueText)
                            }

                            if let value = Double(valueText), value > 0 {
                                let secondary = Double(secondaryValueText)
                                let normal = selectedType.isNormal(value: value, secondaryValue: secondary)
                                HStack {
                                    Text("Status")
                                        .foregroundStyle(.white.opacity(0.6))
                                    Spacer()
                                    Text(normal ? "Normal" : "Check range")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(normal ? AppTheme.softMint : AppTheme.warmCoral)
                                }
                            }
                        }
                    }

                    QuickSaveBar(title: "Save vitals", isEnabled: canSave) {
                        save()
                    }
                }
                .padding(20)
            }
            .background(HealthGradientBackground())
            .navigationTitle("Quick Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            parentStore.ensureSelection(from: parents)
        }
    }

    private func valueField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.decimalPad)
            .font(.title2.weight(.bold).rounded())
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
    }

    private var canSave: Bool {
        guard parentStore.parentID != nil, let value = Double(valueText), value > 0 else { return false }
        if selectedType == .bloodPressure {
            return Double(secondaryValueText) != nil
        }
        return true
    }

    private func save() {
        guard let parent = parentStore.parent(from: parents),
              let value = Double(valueText) else { return }

        let metric = HealthMetric(
            type: selectedType,
            value: value,
            secondaryValue: Double(secondaryValueText),
            parent: parent
        )
        modelContext.insert(metric)
        dismiss()
    }
}

#Preview {
    QuickLogView()
        .environmentObject(SelectedParentStore())
        .modelContainer(SampleData.previewContainer)
}
