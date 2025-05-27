import SwiftUI
import SwiftData
import PhotosUI

struct EditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    // The item to be edited. Use @Bindable to allow two-way binding from form fields.
    @Bindable var item: Item

    // State variables to hold temporary changes for the form.
    // Initialize these from the 'item' being edited.
    @State private var itemName: String
    @State private var itemCategory: String
    @State private var itemQuantity: Int
    @State private var itemNotes: String
    @State private var itemSKU: String
    @State private var itemCondition: String
    @State private var itemHeight: Double
    @State private var itemWidth: Double
    @State private var itemLength: Double

    // Photo picker state
    @State private var selectedPhotoPickerItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil // Holds new photo data if selected
    
    // Holds the identifier of the photo currently associated with the item OR a new one if a new photo is picked.
    // This is initialized with the item's existing photoIdentifier.
    @State private var currentPhotoIdentifier: String?

    // To track the original photo identifier, so we know if we need to delete an old photo file.
    private let originalPhotoIdentifier: String?

    private let conditionOptions = ["New", "Like New", "Good", "Fair", "Poor", "For Parts"]
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }

    init(item: Item) {
        _item = Bindable(item) // Initialize @Bindable property wrapper

        // Initialize @State variables with the item's current values
        _itemName = State(initialValue: item.name)
        _itemCategory = State(initialValue: item.category)
        _itemQuantity = State(initialValue: item.quantity)
        _itemNotes = State(initialValue: item.notes ?? "")
        _itemSKU = State(initialValue: item.sku ?? "")
        _itemCondition = State(initialValue: item.condition)
        _itemHeight = State(initialValue: item.height)
        _itemWidth = State(initialValue: item.width)
        _itemLength = State(initialValue: item.length)
        
        _currentPhotoIdentifier = State(initialValue: item.photoIdentifier)
        self.originalPhotoIdentifier = item.photoIdentifier // Store original for comparison
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $itemName)
                    TextField("Category", text: $itemCategory)
                    Picker("Condition", selection: $itemCondition) {
                        ForEach(conditionOptions, id: \.self) { Text($0) }
                    }
                    Stepper("Quantity: \(itemQuantity)", value: $itemQuantity, in: 1...1000)
                }

                Section("Photo") {
                    VStack {
                        if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 10))
                        } else if let identifier = currentPhotoIdentifier, let uiImage = PhotoManager.shared.loadImage(identifier: identifier) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "photo.on.rectangle.angled")
                                .resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 200)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    PhotosPicker(selection: $selectedPhotoPickerItem, matching: .images) {
                        Label(selectedPhotoData != nil || currentPhotoIdentifier != nil ? "Change Photo" : "Add Photo", systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: selectedPhotoPickerItem) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                selectedPhotoData = data
                                currentPhotoIdentifier = UUID().uuidString
                            } else {
                                if newValue == nil {
                                    // If picker explicitly cleared, don't revert currentPhotoIdentifier
                                    // User must use "Remove Photo" button to fully remove.
                                    // Or, if desired, clearing picker could set selectedPhotoData = nil
                                    // and currentPhotoIdentifier to originalPhotoIdentifier.
                                    // Current logic: picker clear means no *new* photo, original sticks unless "Remove" is hit.
                                    // To make picker clear act like "Remove" for the *newly selected* photo, ensure selectedPhotoData is nil:
                                     selectedPhotoData = nil
                                    // And if they cleared a *newly selected* photo, currentPhotoIdentifier might still hold its new UUID.
                                    // Revert to original if they clear a *new* selection from picker?
                                    // This part of logic can be subtle. Let's assume they want to keep original if they cancel a new pick.
                                    // If selectedPhotoPickerItem becomes nil, it implies they cancelled a *new* pick,
                                    // so selectedPhotoData becomes nil. currentPhotoIdentifier should reflect original if no new data.
                                    if self.selectedPhotoData == nil { // If no new data loaded after picker change
                                        self.currentPhotoIdentifier = self.originalPhotoIdentifier
                                    }
                                }
                            }
                        }
                    }
                    
                    if selectedPhotoData != nil || currentPhotoIdentifier != nil {
                        Button("Remove Photo", systemImage: "xmark.circle.fill", role: .destructive) {
                            selectedPhotoPickerItem = nil
                            selectedPhotoData = nil
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
                    TextField("SKU", text: $itemSKU)
                    VStack(alignment: .leading) {
                        Text("Notes:")
                        TextEditor(text: $itemNotes)
                            .frame(height: 100).border(Color.gray.opacity(0.2), width: 1).clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateItem()
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // This ensures that if there's an existing photo, its data is loaded for display
                // if `selectedPhotoData` (for a *newly picked* photo) is nil.
                if selectedPhotoData == nil,
                   let initialId = self.currentPhotoIdentifier, // currentPhotoIdentifier is init with item.photoIdentifier
                   PhotoManager.shared.loadImage(identifier: initialId) != nil {
                    // The Image view itself in the body already attempts this load.
                    // No explicit data load into selectedPhotoData needed here for *existing* images.
                    // selectedPhotoData is only for *newly picked* images from PhotosPicker.
                }
            }
        }
    }

    private func updateItem() {
        item.name = itemName
        item.category = itemCategory
        item.quantity = itemQuantity
        item.notes = itemNotes.isEmpty ? nil : itemNotes
        item.sku = itemSKU.isEmpty ? nil : itemSKU
        item.condition = itemCondition
        item.height = itemHeight
        item.width = itemWidth
        item.length = itemLength

        // Photo Management Logic
        // Case 1: New photo was selected (selectedPhotoData is not nil, currentPhotoIdentifier is new and different from original)
        if let newPhotoData = selectedPhotoData, let newPhotoId = currentPhotoIdentifier, newPhotoId != originalPhotoIdentifier {
            PhotoManager.shared.saveImage(data: newPhotoData, identifier: newPhotoId)
            item.photoIdentifier = newPhotoId
            if let oldId = originalPhotoIdentifier { // If there was an old photo, delete its file
                PhotoManager.shared.deleteImage(identifier: oldId)
            }
        }
        // Case 2: Photo was explicitly removed (currentPhotoIdentifier is nil, but originalPhotoIdentifier might exist)
        else if currentPhotoIdentifier == nil, let oldId = originalPhotoIdentifier {
            PhotoManager.shared.deleteImage(identifier: oldId)
            item.photoIdentifier = nil
        }
        // Case 3: Photo remains unchanged (currentPhotoIdentifier == originalPhotoIdentifier, selectedPhotoData is nil)
        // No action needed for photo file or item.photoIdentifier.
        // Case 4: No photo originally, and still no photo (original is nil, currentPhotoIdentifier is nil)
        // No action needed.
        // Case 5: New photo selected, and there was no original photo
        else if let newPhotoData = selectedPhotoData, let newPhotoId = currentPhotoIdentifier, originalPhotoIdentifier == nil {
            PhotoManager.shared.saveImage(data: newPhotoData, identifier: newPhotoId)
            item.photoIdentifier = newPhotoId
        }


        do {
            try modelContext.save()
        } catch {
            print("Error updating item: \(error.localizedDescription)")
        }
        
        dismiss()
    }
}


// Preview
#Preview {
    @MainActor
    struct EditItemPreviewWrapper: View {
        // This holds the actual ModelContainer instance
        let previewModelContainer: ModelContainer
        
        @State var sampleItem: Item?

        init() {
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                // Create the container first
                let container = try ModelContainer(for: Building.self, Item.self, configurations: config)
                // Assign it to the non-state property
                self.previewModelContainer = container

                let building = Building(name: "Test Building")
                // Use the container's mainContext to insert
                previewModelContainer.mainContext.insert(building)
                
                let itemToEdit = Item(name: "Old Wrench",
                                      photoIdentifier: "sample_preview_photo_id", // Example ID for preview
                                      category: "Tools",
                                      quantity: 1,
                                      parentBuilding: building)
                previewModelContainer.mainContext.insert(itemToEdit)
                _sampleItem = State(initialValue: itemToEdit) // Initialize @State item

            } catch {
                fatalError("Failed to create preview container: \(error)")
            }
        }

        var body: some View {
            if let item = sampleItem {
                EditItemView(item: item)
                    .modelContainer(previewModelContainer) // Pass the container to the view
            } else {
                Text("Loading preview...")
            }
        }
    }
    return EditItemPreviewWrapper()
}
