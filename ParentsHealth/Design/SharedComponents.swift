import SwiftUI
import UIKit

/// Presents the device camera to capture a single photo.
struct CameraImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

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

// MARK: - Bottom tab bar scroll clearance

private struct BottomChromeScrollPaddingKey: EnvironmentKey {
    static let defaultValue: CGFloat = AppTheme.BottomChrome.scrollPadding(showsFAB: true)
}

extension EnvironmentValues {
    var bottomChromeScrollPadding: CGFloat {
        get { self[BottomChromeScrollPaddingKey.self] }
        set { self[BottomChromeScrollPaddingKey.self] = newValue }
    }
}

extension View {
    /// Keeps the last scroll row visible above the custom tab bar and FAB.
    func scrollBottomClearance() -> some View {
        modifier(ScrollBottomClearanceModifier())
    }
}

private struct ScrollBottomClearanceModifier: ViewModifier {
    @Environment(\.bottomChromeScrollPadding) private var padding

    func body(content: Content) -> some View {
        content.padding(.bottom, padding)
    }
}
