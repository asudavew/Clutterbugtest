
// AddBuildingView.swift
import SwiftUI
import SwiftData
import PhotosUI

struct AddBuildingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    // Building Properties
    @State private var buildingName: String = ""
    @State private var buildingHeight: Double = 10.0
    @State private var buildingWidth: Double = 20.0
    @State private var buildingLength: Double = 30.0
    
    @State private var mapLabel: String = ""

    // Photo
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var photoIdentifier: String? = nil

    private var numberFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }
    
    private var canSave: Bool {
        !buildingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Building Details") {
                    TextField("Building Name (e.g., Workshop, Garage)", text: $buildingName)
                    // mapLabel will be TextField in Map Placeholder section
                }

                Section("Physical Dimensions (feet)") {
                    HStack { Text("Length:"); TextField("Length", value: $buildingLength, formatter: numberFormatter).keyboardType(.decimalPad) }
                    HStack { Text("Width:"); TextField("Width", value: $buildingWidth, formatter: numberFormatter).keyboardType(.decimalPad) }
                    HStack { Text("Height:"); TextField("Height", value: $buildingHeight, formatter: numberFormatter).keyboardType(.decimalPad) }
                }
                
                Section("Photo (Optional)") {
                    if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage).resizable().scaledToFit().frame(maxHeight: 200)
                    }
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        Label(selectedPhotoItem == nil ? "Add Photo" : "Change Photo", systemImage: "camera")
                    }
                    if selectedPhotoItem != nil {
                        Button("Remove Photo", systemImage: "xmark.circle.fill", role: .destructive) {
                            selectedPhotoItem = nil; selectedPhotoData = nil; photoIdentifier = nil
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            selectedPhotoData = data
                            photoIdentifier = UUID().uuidString
                        } else {
                            selectedPhotoData = nil
                            if newValue == nil { photoIdentifier = nil } // Clear ID if picker selection is fully cleared
                        }
                    }
                }
                
                Section("Map Details") {
                     Text("Initial map placement will use defaults. You can adjust position and size on the map later.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Custom Map Label (Optional, defaults to Name)", text: $mapLabel)
                        .onSubmit {
                            if mapLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                mapLabel = buildingName
                            }
                        }
                }
            }
            .navigationTitle("Add New Building")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveBuilding() }
                    .disabled(!canSave)
                }
            }
            .onChange(of: buildingName) { oldValue, newValue in
                if mapLabel.isEmpty || mapLabel == oldValue {
                    mapLabel = newValue
                }
            }
            .onAppear { // Ensure mapLabel is initialized if buildingName is already set (e.g. if view re-appears)
                if mapLabel.isEmpty && !buildingName.isEmpty {
                    mapLabel = buildingName
                }
            }
        }
    }

    private func saveBuilding() {
        if let data = selectedPhotoData, let id = photoIdentifier {
            PhotoManager.shared.saveImage(data: data, identifier: id)
        } else if photoIdentifier != nil && selectedPhotoData == nil {
            photoIdentifier = nil
        }

        let finalMapLabel = mapLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? buildingName : mapLabel

        let newBuilding = Building(
            name: buildingName,
            photoIdentifier: photoIdentifier,
            height: buildingHeight,
            width: buildingWidth,
            length: buildingLength,
            // VVVVVV Assigning default map properties VVVVVV
            mapX: 75.0,      // Example default X (different from "My Workshop"'s potential 150)
            mapY: 300.0,     // Example default Y (different from "My Workshop"'s potential 200)
            mapWidth: 160.0, // Example default width
            mapHeight: 110.0, // Example default height
            shapeType: "rectangle", // Default shape
            // ^^^^^^ End of default map properties ^^^^^^
            mapLabel: finalMapLabel
        )
        modelContext.insert(newBuilding)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving new building: \(error.localizedDescription)")
            if let id = photoIdentifier { PhotoManager.shared.deleteImage(identifier: id) }
        }
    }
}

#Preview {
    AddBuildingView()
        .modelContainer(for: [Building.self, Item.self], inMemory: true)
}

