import SwiftUI
import SwiftData
import PhotosUI // For PhotosPicker

struct AddItemView: View {
    // Environment for data handling and dismissal
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    // The building this new item will belong to
    let targetBuilding: Building

    // State variables for item properties
    @State private var itemName: String = ""
    @State private var itemCategory: String = ""
    @State private var itemQuantity: Int = 1
    @State private var itemNotes: String = ""
    @State private var itemSKU: String = ""
    
    // Condition options and selection
    private let conditionOptions = ["New", "Like New", "Good", "Fair", "Poor", "For Parts"]
    @State private var itemCondition: String = "Good" // Default condition

    // Measurement states (in inches for Item)
    @State private var itemHeight: Double = 0.0
    @State private var itemWidth: Double = 0.0
    @State private var itemLength: Double = 0.0

    // Photo picker state
    @State private var selectedPhotoPickerItem: PhotosPickerItem? = nil // Renamed for clarity from selectedPhotoItem
    @State private var selectedPhotoData: Data? = nil
    @State private var currentPhotoIdentifier: String? = nil // Stores the UUID string for the currently selected photo

    // Formatter for numeric input
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name (e.g., Wrench)", text: $itemName)
                    TextField("Category (e.g., Tools)", text: $itemCategory)
                    
                    Picker("Condition", selection: $itemCondition) {
                        ForEach(conditionOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    
                    Stepper("Quantity: \(itemQuantity)", value: $itemQuantity, in: 1...1000)
                }

                Section("Photo") {
                    if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    PhotosPicker(selection: $selectedPhotoPickerItem, matching: .images, photoLibrary: .shared()) {
                        Label(selectedPhotoPickerItem == nil ? "Add Photo" : "Change Photo", systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: selectedPhotoPickerItem) { oldValue, newValue in
                        Task {
                            // If an existing photo was selected, its identifier is currentPhotoIdentifier.
                            // We don't delete it from disk yet, only if the item is saved with a *new* photo or no photo.
                            
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                selectedPhotoData = data
                                // Generate a new identifier for the *newly selected* photo.
                                // If an old photo was selected, its identifier is still in currentPhotoIdentifier
                                // but it's effectively "orphaned" from this view's perspective until save.
                                currentPhotoIdentifier = UUID().uuidString
                            } else {
                                // User cleared selection in picker or load failed
                                selectedPhotoData = nil
                                // currentPhotoIdentifier = nil // Important: clear if no photo is selected
                                // No, keep currentPhotoIdentifier if a photo *was* selected and then user *cancelled* picker.
                                // Only set to nil if user explicitly removes via our button or if save happens with no photo.
                                if newValue == nil { // Explicitly checking if the picker item became nil
                                    currentPhotoIdentifier = nil
                                }
                            }
                        }
                    }
                    
                    if selectedPhotoPickerItem != nil || selectedPhotoData != nil { // Show remove if there's a picker item or data
                        Button("Remove Photo", systemImage: "xmark.circle.fill", role: .destructive) {
                            selectedPhotoPickerItem = nil
                            selectedPhotoData = nil
                            // The actual file for currentPhotoIdentifier isn't deleted from disk yet.
                            // It will only be saved if `saveItem` proceeds with it.
                            // For a *new* item, if a photo was selected and then removed,
                            // we just ensure currentPhotoIdentifier is nil so nothing is saved.
                            currentPhotoIdentifier = nil
                        }
                        .tint(.red)
                    }
                }

                Section("Measurements (inches)") {
                    HStack { Text("H:"); TextField("Height", value: $itemHeight, formatter: numberFormatter).keyboardType(.decimalPad) }
                    HStack { Text("W:"); TextField("Width", value: $itemWidth, formatter: numberFormatter).keyboardType(.decimalPad) }
                    HStack { Text("L:"); TextField("Length", value: $itemLength, formatter: numberFormatter).keyboardType(.decimalPad) }
                }

                Section("Optional Info") {
                    TextField("SKU (Optional)", text: $itemSKU)
                    VStack(alignment: .leading) {
                        Text("Notes (Optional):")
                        TextEditor(text: $itemNotes)
                            .frame(height: 100)
                            .border(Color.gray.opacity(0.2), width: 1)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .navigationTitle("Add New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveItem() {
        guard !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Item name cannot be empty.")
            return
        }

        var identifierToSaveWithItem: String? = nil

        // Only save the photo and use its identifier if both data and an identifier exist
        if let photoData = selectedPhotoData, let definiteIdentifier = currentPhotoIdentifier {
            PhotoManager.shared.saveImage(data: photoData, identifier: definiteIdentifier)
            identifierToSaveWithItem = definiteIdentifier
        }
        // If selectedPhotoData is nil (no photo chosen or removed),
        // currentPhotoIdentifier should also be nil (or ignored),
        // so identifierToSaveWithItem remains nil, and no photoIdentifier is saved with the Item.

        let newItem = Item(
            name: itemName,
            photoIdentifier: identifierToSaveWithItem, // This will be nil if no photo was selected/kept
            height: itemHeight,
            width: itemWidth,
            length: itemLength,
            category: itemCategory,
            quantity: itemQuantity,
            notes: itemNotes.isEmpty ? nil : itemNotes,
            sku: itemSKU.isEmpty ? nil : itemSKU,
            condition: itemCondition,
            parentBuilding: targetBuilding
        )

        modelContext.insert(newItem)
        
        do {
            try modelContext.save()
            print("Item saved successfully. Photo ID: \(identifierToSaveWithItem ?? "None")")
        } catch {
            print("Error saving new item: \(error.localizedDescription)")
            // If save fails, we might have an orphaned photo file.
            // More robust error handling could delete it here.
            if let id = identifierToSaveWithItem {
                print("Attempting to clean up orphaned photo due to save error: \(id)")
                PhotoManager.shared.deleteImage(identifier: id)
            }
        }
        
        dismiss()
    }
}

// Preview (same as before, ensure it's MainActor if needed)
#Preview {
    @MainActor
    struct PreviewWrapper: View {
        @State var previewContainer: ModelContainer
        @State var workshop: Building?

        init() {
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: Building.self, Item.self, configurations: config)
                _previewContainer = State(initialValue: container)
                let exampleBuilding = Building(name: "Preview Workshop")
                container.mainContext.insert(exampleBuilding)
                _workshop = State(initialValue: exampleBuilding)
            } catch {
                fatalError("Failed to create preview container: \(error)")
            }
        }
        var body: some View {
            if let workshop = workshop {
                AddItemView(targetBuilding: workshop)
                    .modelContainer(previewContainer)
            } else {
                Text("Loading Preview...")
            }
        }
    }
    return PreviewWrapper()
}
