import SwiftUI

/// Shared parent selector used across Labs, Charts, Dashboard.
struct ParentChipPicker: View {
    let parents: [ParentProfile]
    @Binding var selectedParentID: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(parents) { parent in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedParentID = parent.id
                        }
                    } label: {
                        HStack(spacing: 8) {
                            ParentAvatar(initials: parent.initials, hue: parent.avatarHue, size: 28)
                            Text(parent.name)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .liquidGlass(cornerRadius: 18, interactive: true)
                        .opacity(isSelected(parent) ? 1 : 0.55)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(parent.name) profile")
                    .accessibilityAddTraits(isSelected(parent) ? .isSelected : [])
                }
            }
        }
    }

    private func isSelected(_ parent: ParentProfile) -> Bool {
        selectedParentID == parent.id
    }
}

struct SourceSegmentPicker: View {
    @Binding var source: ChartDataSource

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ChartDataSource.allCases) { item in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        source = item
                    }
                } label: {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(source == item ? AppTheme.deepTeal.opacity(0.65) : Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .liquidGlass(cornerRadius: 18)
    }
}

enum ChartDataSource: String, CaseIterable, Identifiable {
    case vitals
    case labs

    var id: String { rawValue }
    var title: String {
        switch self {
        case .vitals: return "Daily Vitals"
        case .labs: return "Lab Trends"
        }
    }
}

struct QuickSaveBar: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isEnabled ? AppTheme.softMint.opacity(0.45) : Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.sectionHeadline)
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}
