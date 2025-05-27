// EditBuildingView.swift
import SwiftUI
import SwiftData
import PhotosUI

struct EditBuildingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Bindable var building: Building

    @State private var buildingName: String
    @State private var buildingHeight: Double
    @State private var buildingWidth: Double
    @State private var buildingLength: Double
    @State private var mapLabel: String
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var currentPhotoIdentifier: String?
    private let originalPhotoIdentifier: String?

    // VVVVVV CORRECTED COMPUTED PROPERTY VVVVVV
    private var numberFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f // Ensured return
    }
    // ^^^^^^ CORRECTED COMPUTED PROPERTY ^^^^^^
    
    private var canSave: Bool { !buildingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    init(building: Building) {
        _building = Bindable(building)

        _buildingName = State(initialValue: building.name)
        _buildingHeight = State(initialValue: building.height)
        _buildingWidth = State(initialValue: building.width)
        _buildingLength = State(initialValue: building.length)
        _mapLabel = State(initialValue: building.mapLabel ?? building.name)
        
        _currentPhotoIdentifier = State(initialValue: building.photoIdentifier)
        self.originalPhotoIdentifier = building.photoIdentifier
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Building Details") {
                    TextField("Building Name", text: $buildingName)
                }

                Section("Physical Dimensions (feet)") {
                    HStack { Text("Length:"); TextField("L", value: $buildingLength, formatter: numberFormatter).keyboardType(.decimalPad) }
                    HStack { Text("Width:"); TextField("W", value: $buildingWidth, formatter: numberFormatter).keyboardType(.decimalPad) }
                    HStack { Text("Height:"); TextField("H", value: $buildingHeight, formatter: numberFormatter).keyboardType(.decimalPad) }
                }
                
                Section("Photo (Optional)") {
                    VStack {
                        if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage).resizable().scaledToFit().frame(maxHeight: 200)
                        } else if let photoId = currentPhotoIdentifier, let uiImage = PhotoManager.shared.loadImage(identifier: photoId) {
                            Image(uiImage: uiImage).resizable().scaledToFit().frame(maxHeight: 200)
                        } else {
                            Image(systemName: "building.2").resizable().scaledToFit().frame(maxHeight: 100).foregroundColor(.gray)
                        }
                    }
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(currentPhotoIdentifier != nil || selectedPhotoData != nil ? "Change Photo" : "Add Photo", systemImage: "camera")
                    }
                    if currentPhotoIdentifier != nil || selectedPhotoData != nil {
                        Button("Remove Photo", systemImage: "xmark.circle.fill", role: .destructive) {
                            selectedPhotoItem = nil; selectedPhotoData = nil; currentPhotoIdentifier = nil
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { oldValue, newValue in // Ensure correct var names if you copied from AddItemView
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            selectedPhotoData = data
                            currentPhotoIdentifier = UUID().uuidString
                        } else if newValue == nil {
                             selectedPhotoData = nil
                             // If they clear picker, what about currentPhotoIdentifier?
                             // If it was original, keep it. If it was a new pick, clear it too.
                             // This depends on desired UX. CurrentPhotoIdentifier might need to revert to originalPhotoIdentifier here.
                             // For now, this means if they pick then clear, currentPhotoIdentifier (new UUID) sticks,
                             // then "Remove Photo" would clear it fully. Or, if no new pick, original stays.
                        }
                    }
                }
                
                Section("Map Label") {
                    TextField("Custom Map Label", text: $mapLabel)
                        .onSubmit {
                             if mapLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                mapLabel = buildingName
                            }
                        }
                    Text("Other map properties (position, size, shape) are set by interacting with the map directly.")
                        .font(.caption).foregroundColor(.gray)
                }
            }
            .navigationTitle("Edit Building")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { updateBuilding() }.disabled(!canSave) }
            }
             .onChange(of: buildingName) { oldValue, newValue in
                if mapLabel == oldValue {
                    mapLabel = newValue
                }
            }
        }
    }

    private func updateBuilding() {
        building.name = buildingName
        building.height = buildingHeight
        building.width = buildingWidth
        building.length = buildingLength
        building.mapLabel = mapLabel.isEmpty ? buildingName : mapLabel

        if let newImageData = selectedPhotoData, let newPhotoId = currentPhotoIdentifier, newPhotoId != originalPhotoIdentifier {
            PhotoManager.shared.saveImage(data: newImageData, identifier: newPhotoId)
            building.photoIdentifier = newPhotoId
            if let oldId = originalPhotoIdentifier { PhotoManager.shared.deleteImage(identifier: oldId) }
        }
        else if currentPhotoIdentifier == nil, let oldId = originalPhotoIdentifier {
            PhotoManager.shared.deleteImage(identifier: oldId)
            building.photoIdentifier = nil
        }
        else if let newImageData = selectedPhotoData, let newPhotoId = currentPhotoIdentifier, originalPhotoIdentifier == nil {
             PhotoManager.shared.saveImage(data: newImageData, identifier: newPhotoId)
             building.photoIdentifier = newPhotoId
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error updating building: \(error.localizedDescription)")
        }
    }
}

#Preview {
    @MainActor
    struct EditBuildingPreviewWrapper: View {
        @State var previewContainer: ModelContainer
        @State var sampleBuilding: Building?
        init() {
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: Building.self, Item.self, configurations: config)
                _previewContainer = State(initialValue: container)
                let building = Building(name: "Shed To Edit") // Add other params if init requires
                container.mainContext.insert(building)
                _sampleBuilding = State(initialValue: building)
            } catch { fatalError("Preview setup failed: \(error)")}
        }
        var body: some View {
            if let building = sampleBuilding {
                EditBuildingView(building: building)
                    .modelContainer(previewContainer)
            } else { Text("Loading preview...") }
        }
    }
    return EditBuildingPreviewWrapper()
}
