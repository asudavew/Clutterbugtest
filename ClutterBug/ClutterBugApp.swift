import SwiftUI
import SwiftData

@main
struct ClutterBugApp: App {

    let sharedModelContainer: ModelContainer

    init() {
        // Define the schema including all your SwiftData models
        let schema = Schema([
            Building.self,
            Item.self,
            // Add future models like Room.self, StorageArea.self, etc., here when defined
        ])
        
        // Configure the model container (persistent store)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If the container can't be created, the app is unlikely to function.
            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView() // Your main view, which includes the TabView
                .onAppear {
                    // Ensure the default building exists when the app appears.
                    // Task is used for async operations, though this one is currently synchronous.
                    Task {
                       await DataSetup.ensureDefaultBuildingExists(modelContext: sharedModelContainer.mainContext)
                    }
                }
        }
        // Inject the modelContainer into the SwiftUI environment,
        // making the mainContext available to all child views via @Environment(\.modelContext).
        .modelContainer(sharedModelContainer)
    }
}

// Helper struct for one-time data setup, like creating the default building
struct DataSetup {
    @MainActor // Ensures UI-related or context operations are on the main thread if needed
    static func ensureDefaultBuildingExists(modelContext: ModelContext) async {
        let defaultBuildingName = "My Workshop"
        
        // Predicate to find if a building with the default name already exists
        let predicate = #Predicate<Building> { building in
            building.name == defaultBuildingName
        }
        
        let fetchDescriptor = FetchDescriptor<Building>(predicate: predicate)

        do {
            let existingBuildings = try modelContext.fetch(fetchDescriptor)
            
            if existingBuildings.isEmpty {
                // Default building doesn't exist, so create it with map data.
                print("Default building '\(defaultBuildingName)' not found. Creating it now with map data.")
                
                let newBuilding = Building(
                    name: defaultBuildingName,
                    // Provide some default physical dimensions (optional, but good for map later)
                    width: 30.0,      // Example: 30 units wide (e.g., feet)
                    length: 40.0,     // Example: 40 units long (e.g., feet)
                    // Provide some default map data
                    mapX: 150.0,      // Example X position on canvas (center-ish for a typical phone width)
                    mapY: 200.0,      // Example Y position on canvas
                    mapWidth: 250.0,  // Example width of shape on canvas
                    mapHeight: 180.0, // Example height of shape on canvas (derived from aspect or fixed)
                    shapeType: "rectangle", // Default shape type
                    mapLabel: defaultBuildingName // mapLabel defaults to name if nil, but explicit is fine
                )
                modelContext.insert(newBuilding)
                
                // Save the context to persist the new building
                try modelContext.save()
                print("Default building '\(defaultBuildingName)' created with map data and saved.")
                
            } else {
                print("Default building '\(defaultBuildingName)' already exists.")
                // Optional: For existing users getting an update, you might want to
                // check if existingBuildings.first has map data and add it if not.
                // For now, we assume if it exists, it's adequately set up or will be handled manually.
                // Example:
                // if let building = existingBuildings.first, building.mapX == nil {
                //     building.mapX = 150.0
                //     building.mapY = 200.0
                //     // ... set other map properties ...
                //     try modelContext.save()
                //     print("Updated existing default building with map data.")
                // }
            }
        } catch {
            // Handle potential errors during fetch or save
            print("Error in DataSetup.ensureDefaultBuildingExists: \(error.localizedDescription)")
        }
    }
}
