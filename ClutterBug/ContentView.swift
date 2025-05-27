
import SwiftUI
import SwiftData

struct ContentView: View {
    // Environment
    @Environment(\.modelContext) private var modelContext
    
    // TabView State
    @State private var selectedTab: AppTab = .home

    // Onboarding State
    @AppStorage("isOnboardingComplete_ClutterBug_v1") private var isOnboardingComplete: Bool = false
    
    // Hierarchy Choice State
    @AppStorage("userHierarchyChoice") private var userHierarchyChoice: String = "Simple"

    enum AppTab: Hashable {
        case home, scan, search, settings
    }

    // --- Home Tab Specific State & Data (for Simple Mode) ---
    @State private var homeDisplayMode_Simple: HomeDisplayMode_Simple = .list
    enum HomeDisplayMode_Simple: String, CaseIterable, Identifiable {
        case list = "List"; case map = "Map"
        var id: String { self.rawValue }
    }

    @Query(filter: #Predicate<Building> { $0.name == "My Workshop" })
    private var defaultBuildings_SimpleQuery: [Building] // Query specifically for "My Workshop"
    private var workshop_SimpleMode: Building? { defaultBuildings_SimpleQuery.first }
    
    @State private var showingAddItemSheet_Simple = false
    @State private var itemToEdit_Simple: Item? = nil
    
    // --- Data & State for ADVANCED Mode ---
    @Query(sort: \Building.name) private var allBuildings_Advanced: [Building] // All buildings
    @State private var showingAddBuildingSheet_Advanced = false
    @State private var buildingToEdit_Advanced: Building? = nil
    @State private var homeDisplayMode_Advanced: HomeDisplayMode_Advanced = .list
    enum HomeDisplayMode_Advanced: String, CaseIterable, Identifiable {
        case list = "Buildings List"; case map = "Building Map" // Renamed "Buildings Map" to "Building Map" for clarity
        var id: String { self.rawValue }
    }
    @State private var focusedBuilding_Advanced: Building? = nil // The single building to show on map in Advanced mode

    // --- Main View Body ---
    var body: some View {
        TabView(selection: $selectedTab) {
            homeTabContent
                .tabItem { Label("Home", systemImage: "house.fill") }.tag(AppTab.home)
            UPCScanView()
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }.tag(AppTab.scan)
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }.tag(AppTab.search)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(AppTab.settings)
        }
        .fullScreenCover(isPresented: .constant(!isOnboardingComplete)) {
            OnboardingView(isOnboardingComplete: $isOnboardingComplete)
        }
    }

    // --- Home Tab Content (Conditional) ---
    private var homeTabContent: some View {
        Group {
            if userHierarchyChoice == "Simple" {
                simpleModeHomeView
            } else { // "Advanced"
                advancedModeHomeView
            }
        }
    }
    
    // --- Content for SIMPLE Mode ---
    private var simpleModeHomeView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View Mode", selection: $homeDisplayMode_Simple) {
                    ForEach(HomeDisplayMode_Simple.allCases) { mode in Text(mode.rawValue).tag(mode) }
                }
                .pickerStyle(.segmented).padding([.horizontal, .top]).padding(.bottom, 8)
                
                Group {
                    if homeDisplayMode_Simple == .list {
                        itemListContent_SimpleMode
                    } else {
                        // 🔧 FIX: Pass the single workshop to the simplified MapView with .id() modifier
                        MapView(buildingToDisplay: workshop_SimpleMode,
                                switchToListView: { homeDisplayMode_Simple = .list })
                            .id("simple-\(workshop_SimpleMode?.id.uuidString ?? "none")")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(determineHomeTitle_SimpleMode())
            .toolbar {
                if homeDisplayMode_Simple == .list && workshop_SimpleMode != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showingAddItemSheet_Simple = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                    }
                }
            }
            .sheet(isPresented: $showingAddItemSheet_Simple) {
                if let currentWorkshop = workshop_SimpleMode { AddItemView(targetBuilding: currentWorkshop) }
                else { Text("Error: Default workshop missing.").padding() }
            }
            .sheet(item: $itemToEdit_Simple) { item in EditItemView(item: item) }
        }
    }
    
    private func determineHomeTitle_SimpleMode() -> String {
        if homeDisplayMode_Simple == .map {
            return "\(workshop_SimpleMode?.name ?? "Workshop") Map" // Simplified title
        } else {
            return workshop_SimpleMode?.name ?? "My Workshop Items"
        }
    }

    private var itemListContent_SimpleMode: some View {
        Group {
            if let currentWorkshop = workshop_SimpleMode {
                if currentWorkshop.items?.isEmpty ?? true {
                    ContentUnavailableView { Label("No Items Yet!", systemImage: "archivebox.fill") }
                    description: { Text("Tap '+' to add items to '\(currentWorkshop.name)'.") }
                    actions: { Button { showingAddItemSheet_Simple = true } label: { Text("Add First Item").padding(.horizontal) }.buttonStyle(.borderedProminent) }
                } else {
                    List {
                        ForEach(currentWorkshop.items?.sorted(by: { $0.name < $1.name }) ?? []) { item in
                            ItemRow(item: item, onEdit: { self.itemToEdit_Simple = item })
                        }
                    }
                }
            } else {
                ContentUnavailableView("Workshop Not Found", systemImage: "questionmark.folder.fill")
            }
        }
    }

    // --- Content for ADVANCED Mode ---
    private var advancedModeHomeView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View Mode", selection: $homeDisplayMode_Advanced) {
                    ForEach(HomeDisplayMode_Advanced.allCases) { mode in Text(mode.rawValue).tag(mode) }
                }
                .pickerStyle(.segmented).padding([.horizontal, .top]).padding(.bottom, 8)

                Group {
                    if homeDisplayMode_Advanced == .list {
                        buildingList_AdvancedMode
                    } else { // .map - shows the focusedBuilding_Advanced
                        // 🔧 FIX: Pass the single focused building to the simplified MapView with .id() modifier
                        MapView(buildingToDisplay: focusedBuilding_Advanced,
                                switchToListView: { // This action takes user back to the Buildings List
                                    homeDisplayMode_Advanced = .list
                                    // focusedBuilding_Advanced = nil // Optionally clear focus
                                })
                            .id("advanced-\(focusedBuilding_Advanced?.id.uuidString ?? "none")")
                        
                        // If no building is focused, MapView will show its "No Building to Display"
                        // or you could show a different placeholder here.
                        if focusedBuilding_Advanced == nil && homeDisplayMode_Advanced == .map {
                             ContentUnavailableView("Select a Building", systemImage: "hand.tap.fill", description: Text("Tap a building from the list to see its map."))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(determineHomeTitle_AdvancedMode())
            .toolbar {
                if homeDisplayMode_Advanced == .list {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showingAddBuildingSheet_Advanced = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddBuildingSheet_Advanced) { AddBuildingView() }
            .sheet(item: $buildingToEdit_Advanced) { building in EditBuildingView(building: building) }
            .onChange(of: homeDisplayMode_Advanced) {
                if homeDisplayMode_Advanced == .list {
                    // focusedBuilding_Advanced = nil // Optionally clear focus when switching to list
                }
            }
        }
    }
    
    private var buildingList_AdvancedMode: some View {
        Group {
            if allBuildings_Advanced.isEmpty {
                ContentUnavailableView("No Buildings Yet", systemImage: "building.2.fill",
                                     description: Text("Tap '+' to create your first building."))
            } else {
                List {
                    ForEach(allBuildings_Advanced) { building in
                        BuildingRowView(
                            building: building,
                            onEdit: { buildingToEdit_Advanced = building },
                            onDelete: {
                                if focusedBuilding_Advanced == building { focusedBuilding_Advanced = nil }
                                deleteBuilding(building)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedBuilding_Advanced = building
                            homeDisplayMode_Advanced = .map
                        }
                    }
                }
            }
        }
    }
    
    private func determineHomeTitle_AdvancedMode() -> String {
        switch homeDisplayMode_Advanced {
        case .list: return "My Buildings"
        case .map:
            if let focused = focusedBuilding_Advanced {
                return "\(focused.name) Map Detail" // Title reflects focused building map
            }
            return "Select Building for Map" // Prompt if no building is focused for map
        }
    }

    private func deleteBuilding(_ building: Building) {
        if let photoId = building.photoIdentifier { PhotoManager.shared.deleteImage(identifier: photoId) }
        modelContext.delete(building)
    }
}

// Preview
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Building.self, Item.self, configurations: config)
        
        let workshopBuilding = Building(name: "My Workshop", mapX: 0, mapY: 0, mapWidth: 200, mapHeight: 150, shapeType: "rectangle")
        container.mainContext.insert(workshopBuilding)
        
        let advBuilding1 = Building(name: "Main Shed", height: 12, width: 20, length: 25, mapX: 250, mapY: 0, mapWidth: 100, mapHeight: 100, shapeType: "rectangle")
        let advBuilding2 = Building(name: "Old Garage", height: 10, width: 22, length: 22, mapX: 0, mapY: 200, mapWidth: 180, mapHeight: 180, shapeType: "rectangle")
        container.mainContext.insert(advBuilding1)
        container.mainContext.insert(advBuilding2)

        // UserDefaults.standard.setValue("Advanced", forKey: "userHierarchyChoice") // For testing advanced mode in preview

        return ContentView()
            .modelContainer(container)
            
    } catch {
        fatalError("Failed to create model container for ContentView preview: \(error)")
    }
}
