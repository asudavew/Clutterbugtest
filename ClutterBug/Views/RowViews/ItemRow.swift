
import SwiftUI
import SwiftData

struct ItemRow: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    @State private var displayImage: Image? = nil

    // --- New: Callback for edit action ---
    var onEdit: () -> Void // Closure to be called when edit is tapped

    // (loadImage function remains the same)
    private func loadImage() {
        if let identifier = item.photoIdentifier, !identifier.isEmpty {
            if let uiImage = PhotoManager.shared.loadImage(identifier: identifier) {
                self.displayImage = Image(uiImage: uiImage)
                return
            } else {
                print("ItemRow: Failed to load image for identifier \(identifier)")
            }
        }
        self.displayImage = Image(systemName: "archivebox")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                (displayImage ?? Image(systemName: "photo.on.rectangle.angled"))
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 8))
                    .background(Color.gray.opacity(0.1))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name.isEmpty ? "Untitled Item" : item.name).font(.headline).lineLimit(1)
                    if !item.category.isEmpty {
                        Text("Category: \(item.category)").font(.subheadline).foregroundColor(.gray).lineLimit(1)
                    }
                    Text("Quantity: \(item.quantity)").font(.caption).foregroundColor(.gray)
                }
                Spacer()
            }
            
            HStack(spacing: 15) {
                Spacer()
                Button {
                    // --- Call the onEdit closure ---
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil.circle.fill")
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    deleteItem()
                } label: {
                    Label("Delete", systemImage: "trash.circle.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 5)
        }
        .padding(.vertical, 10)
        .onAppear { loadImage() }
        .onChange(of: item.photoIdentifier) { oldValue, newValue in
            print("ItemRow: photoIdentifier changed for \(item.name). Reloading image.")
            loadImage()
        }
    }

    // (deleteItem function remains the same)
    private func deleteItem() {
        if let identifier = item.photoIdentifier, !identifier.isEmpty {
            PhotoManager.shared.deleteImage(identifier: identifier)
        }
        modelContext.delete(item)
    }
}

// Update the ItemRow Preview to provide a dummy onEdit closure
#Preview {
    @MainActor
    struct ItemRowPreviewWrapper: View {
        // ... (preview setup code from before, just add onEdit to ItemRow instances)
        @State var previewContainer: ModelContainer
        @State var sampleItemWithPhoto: Item?
        @State var sampleItemWithoutPhoto: Item?

        init() {
            // ... (same init as before) ...
             do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: Building.self, Item.self, configurations: config)
                _previewContainer = State(initialValue: container)

                let sampleBuilding = Building(name: "Preview Workshop")
                container.mainContext.insert(sampleBuilding)
                
                let photoIdForPreview = "preview_photo_id_123"
                
                let item1 = Item(name: "Shiny Hammer", photoIdentifier: photoIdForPreview, category: "Hand Tools", quantity: 1, parentBuilding: sampleBuilding)
                container.mainContext.insert(item1)
                _sampleItemWithPhoto = State(initialValue: item1)

                let item2 = Item(name: "Old Screwdriver", photoIdentifier: nil, category: "Hand Tools", quantity: 5, parentBuilding: sampleBuilding)
                container.mainContext.insert(item2)
                _sampleItemWithoutPhoto = State(initialValue: item2)
                
            } catch {
                fatalError("Failed to create model container for ItemRow preview: \(error)")
            }
        }


        var body: some View {
            NavigationStack {
                List {
                    if let item = sampleItemWithPhoto {
                        ItemRow(item: item, onEdit: { print("Edit tapped for \(item.name) in preview") }) // Add onEdit
                    }
                    if let item = sampleItemWithoutPhoto {
                        ItemRow(item: item, onEdit: { print("Edit tapped for \(item.name) in preview") }) // Add onEdit
                    }
                }
                .modelContainer(previewContainer)
            }
        }
    }
    return ItemRowPreviewWrapper()
}
