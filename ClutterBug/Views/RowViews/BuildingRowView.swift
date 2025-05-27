// BuildingRowView.swift
import SwiftUI
import SwiftData // If Building is a SwiftData model

struct BuildingRowView: View {
    @Bindable var building: Building // Assuming Building is an @Model
    
    var onEdit: () -> Void
    var onDelete: () -> Void // Direct delete action

    // Placeholder for actual image loading logic if buildings have photos
    private func getBuildingImage() -> Image {
        if let _ = building.photoIdentifier { // A simple check if an ID exists
            // TODO: Load image via PhotoManager using building.photoIdentifier
            return Image(systemName: "photo.on.rectangle.angled") // Placeholder for actual image
        } else {
            return Image(systemName: "building.2.crop.circle.fill") // Default placeholder
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                getBuildingImage()
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .background(Color.gray.opacity(0.1))

                VStack(alignment: .leading) {
                    Text(building.name.isEmpty ? "Untitled Building" : building.name)
                        .font(.headline)
                    // You could add other details like number of rooms or items later
                    if let mapLabel = building.mapLabel, !mapLabel.isEmpty, mapLabel != building.name {
                        Text("Map Label: \(mapLabel)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text("Dimensions: \(String(format: "%.1f", building.length))L x \(String(format: "%.1f", building.width))W x \(String(format: "%.1f", building.height))H ft")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }

            HStack(spacing: 15) {
                Spacer() // Pushes buttons to the right
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil.circle.fill")
                }
                .buttonStyle(.bordered)

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash.circle.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 5)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    // Need a model container and a sample Building for the preview
    @MainActor
    struct BuildingRowPreviewWrapper: View {
        @State var previewContainer: ModelContainer
        @State var sampleBuilding: Building?

        init() {
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: Building.self, Item.self, configurations: config)
                _previewContainer = State(initialValue: container)

                let building = Building(name: "My Awesome Workshop",
                                        photoIdentifier: nil, // Or a dummy one if you test photo loading
                                        height: 10, width: 20, length: 30,
                                        mapX: 10, mapY: 10, mapWidth: 100, mapHeight: 80,
                                        shapeType: "rectangle", mapLabel: "Workshop")
                container.mainContext.insert(building)
                _sampleBuilding = State(initialValue: building)
            } catch {
                fatalError("Failed to create preview model container: \(error)")
            }
        }

        var body: some View {
            List { // Display in a list for realistic context
                if let building = sampleBuilding {
                    BuildingRowView(building: building, onEdit: {
                        print("Edit tapped for \(building.name)")
                    }, onDelete: {
                        print("Delete tapped for \(building.name)")
                        // In a real scenario, you'd call modelContext.delete(building)
                    })
                }
            }
            .modelContainer(previewContainer) // Provide container for @Bindable
        }
    }
    return BuildingRowPreviewWrapper()
}
