import SwiftUI
import SwiftData

struct ParentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @State private var showAddParent = false
    @State private var parentToEdit: ParentProfile?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    ForEach(parents) { parent in
                        NavigationLink {
                            ParentDetailView(parent: parent)
                        } label: {
                            ParentCard(parent: parent)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Edit") { parentToEdit = parent }
                            Button("Delete", role: .destructive) {
                                modelContext.delete(parent)
                            }
                        }
                    }

                    Button {
                        showAddParent = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Parent")
                                .font(.sectionHeadline)
                        }
                        .foregroundStyle(AppTheme.softMint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .liquidGlass(cornerRadius: AppTheme.cardRadius, interactive: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .navigationTitle("Parents")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showAddParent) {
            ParentFormView()
        }
        .sheet(item: $parentToEdit) { parent in
            ParentFormView(parent: parent)
        }
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
                    .font(.title3.weight(.bold).rounded())
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
        .modelContainer(SampleData.previewContainer)
}
