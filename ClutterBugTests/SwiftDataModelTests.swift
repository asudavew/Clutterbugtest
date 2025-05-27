import XCTest
import SwiftData
@testable import ClutterBug

final class SwiftDataModelTests: XCTestCase {

    // These will be recreated for each test in setUpWithError
    var modelContainer: ModelContainer! // Hold the container to ensure its lifecycle
    var modelContext: ModelContext!
    // defaultBuilding will be fetched fresh within each test that needs it, from the current context.
    // We won't store it as an instance variable that persists across the internal state of setUp -> test -> tearDown.
    // Instead, we'll store its ID.
    var defaultBuildingID: UUID!

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([Building.self, Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            // Create a new container for each test. Store it.
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContext = self.modelContainer.mainContext
            
            // Create a building, save it, and store its ID.
            let buildingForSetup = Building(name: "My Workshop")
            self.modelContext.insert(buildingForSetup)
            try self.modelContext.save()
            self.defaultBuildingID = buildingForSetup.id // Store the ID
            
        } catch {
            XCTFail("Failed to set up in-memory SwiftData container: \(error)")
            // Ensure partial setup doesn't leave things in a weird state for other tests.
            self.modelContainer = nil
            self.modelContext = nil
            self.defaultBuildingID = nil
        }
    }

    override func tearDownWithError() throws {
        // Release the container, which should release the context and in-memory store.
        modelContext = nil
        defaultBuildingID = nil
        modelContainer = nil // Important to deallocate the container
        try super.tearDownWithError()
    }

    // Helper to fetch the default building for the current context
    @MainActor
    private func fetchDefaultBuildingForTest() throws -> Building? {
        guard let id = defaultBuildingID else {
            XCTFail("DefaultBuildingID was not set in setUp")
            return nil
        }
        let predicate = #Predicate<Building> { $0.id == id }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    @MainActor
    func testReadItem() throws {
        // Fetch the defaultBuilding fresh for this test, using the current context
        guard let currentDefaultBuilding = try fetchDefaultBuildingForTest() else {
            XCTFail("Could not fetch default building for testReadItem.")
            return
        }

        // Now use 'currentDefaultBuilding' which is guaranteed to be from the active context.
        let item1 = Item(name: "Hammer", category: "Tools", quantity: 1, parentBuilding: currentDefaultBuilding)
        let item2 = Item(name: "Screwdriver", category: "Tools", quantity: 5, parentBuilding: currentDefaultBuilding)
        modelContext.insert(item1)
        modelContext.insert(item2)
        try modelContext.save()

        // Pass the freshly fetched 'currentDefaultBuilding'
        let allItemsOfDefaultBuilding = try fetchAllItems(forBuilding: currentDefaultBuilding)
        XCTAssertEqual(allItemsOfDefaultBuilding.count, 2, "Should fetch 2 items for the default building")

        let hammer = allItemsOfDefaultBuilding.first(where: { $0.name == "Hammer" })
        XCTAssertNotNil(hammer, "Hammer should be found")
        XCTAssertEqual(hammer?.category, "Tools")
    }

    // ... other test methods will also need to use fetchDefaultBuildingForTest()
    // if they rely on a "default building" concept.

    @MainActor
    func testCreateItem() throws {
        guard let currentDefaultBuilding = try fetchDefaultBuildingForTest() else {
            XCTFail("Could not fetch default building for testCreateItem.")
            return
        }
        
        let initialItemCount = try countItems(forBuilding: currentDefaultBuilding)
        
        let newItem = Item(name: "Test Wrench",
                           category: "Tools",
                           quantity: 1,
                           parentBuilding: currentDefaultBuilding)
        
        modelContext.insert(newItem)
        try modelContext.save()

        let finalItemCount = try countItems(forBuilding: currentDefaultBuilding)
        XCTAssertEqual(finalItemCount, initialItemCount + 1, "Item count for this building should increment by 1")
        
        let fetchedItem = try fetchItem(with: newItem.id)
        XCTAssertNotNil(fetchedItem, "Created item should be fetchable")
        XCTAssertEqual(fetchedItem?.name, "Test Wrench", "Fetched item name should match")
        XCTAssertEqual(fetchedItem?.parentBuilding?.id, currentDefaultBuilding.id, "Item should be parented to the default building")
    }
    
    @MainActor
    func testUpdateItem() throws {
        guard let currentDefaultBuilding = try fetchDefaultBuildingForTest() else {
            XCTFail("Could not fetch default building for testUpdateItem.")
            return
        }

        let itemToUpdate = Item(name: "Old Paint Can", category: "Supplies", quantity: 1, parentBuilding: currentDefaultBuilding)
        modelContext.insert(itemToUpdate)
        try modelContext.save()

        let fetchedItemOptional = try fetchItem(with: itemToUpdate.id)
        guard let fetchedItem = fetchedItemOptional else {
            XCTFail("Item to update should be fetchable")
            return
        }
        
        fetchedItem.name = "New Shiny Paint Can"
        fetchedItem.quantity = 2
        try modelContext.save()

        let updatedItem = try fetchItem(with: itemToUpdate.id)
        XCTAssertNotNil(updatedItem, "Updated item should be fetchable")
        XCTAssertEqual(updatedItem?.name, "New Shiny Paint Can", "Item name should be updated")
        XCTAssertEqual(updatedItem?.quantity, 2, "Item quantity should be updated")
    }

    @MainActor
    func testDeleteItem() throws {
        guard let currentDefaultBuilding = try fetchDefaultBuildingForTest() else {
            XCTFail("Could not fetch default building for testDeleteItem.")
            return
        }
        
        let itemToDelete = Item(name: "Disposable Item", category: "Misc", quantity: 1, parentBuilding: currentDefaultBuilding)
        modelContext.insert(itemToDelete)
        try modelContext.save()
        
        let initialItemCount = try countItems(forBuilding: currentDefaultBuilding)
        XCTAssertEqual(initialItemCount, 1, "Should have 1 item (for this building) before delete")

        guard let fetchedItemToDelete = try fetchItem(with: itemToDelete.id) else {
            XCTFail("Could not fetch item to delete")
            return
        }
        modelContext.delete(fetchedItemToDelete)
        try modelContext.save()

        let finalItemCount = try countItems(forBuilding: currentDefaultBuilding)
        XCTAssertEqual(finalItemCount, 0, "Item count (for this building) should be 0 after delete")
        
        let deletedItemCheck = try fetchItem(with: itemToDelete.id)
        XCTAssertNil(deletedItemCheck, "Deleted item should no longer be fetchable")
    }

    // testCascadingDeleteBuildingToItems already creates its own building, so it's fine.
    @MainActor
    func testCascadingDeleteBuildingToItems() throws {
        let buildingForCascadeTest = Building(name: "Cascade Test Building")
        modelContext.insert(buildingForCascadeTest)
        try modelContext.save()

        let buildingIDForTest = buildingForCascadeTest.id

        let item1 = Item(name: "Cascade Item 1", category: "Test", quantity: 1, parentBuilding: buildingForCascadeTest)
        let item2 = Item(name: "Cascade Item 2", category: "Test", quantity: 1, parentBuilding: buildingForCascadeTest)
        modelContext.insert(item1)
        modelContext.insert(item2)
        try modelContext.save()

        let itemsCountBeforeDelete = try countItems(forBuilding: buildingForCascadeTest)
        XCTAssertEqual(itemsCountBeforeDelete, 2, "Should have 2 items in 'Cascade Test Building' before its deletion")

        modelContext.delete(buildingForCascadeTest)
        try modelContext.save()

        let itemsCountAfterDelete = try countItems(forBuildingID: buildingIDForTest)
        XCTAssertEqual(itemsCountAfterDelete, 0, "Items for 'Cascade Test Building' should be deleted due to cascade")
        
        let verificationFetchDescriptor = FetchDescriptor<Building>(predicate: #Predicate { $0.id == buildingIDForTest })
        let fetchedBuildingsAfterDelete = try modelContext.fetch(verificationFetchDescriptor)
        XCTAssertTrue(fetchedBuildingsAfterDelete.isEmpty, "'Cascade Test Building' should be deleted from the store")
        
        // This check is for the building created in setUp, using its ID
        if let mainDefaultBuildingTestID = self.defaultBuildingID, mainDefaultBuildingTestID != buildingIDForTest {
            let defaultBuildingStillExistsPredicate = #Predicate<Building> { buildingRecord in
                buildingRecord.id == mainDefaultBuildingTestID
            }
            let defaultBuildingFetch = try modelContext.fetch(FetchDescriptor(predicate: defaultBuildingStillExistsPredicate))
            XCTAssertFalse(defaultBuildingFetch.isEmpty, "The main defaultBuilding from setUp should still exist if it was different.")
        }
    }


    // Helper methods (no changes needed here other than ensuring predicates are robust)
    @MainActor
    private func countItems(forBuilding: Building? = nil) throws -> Int {
        var descriptor = FetchDescriptor<Item>()
        if let building = forBuilding {
            let buildingID = building.id
            descriptor.predicate = #Predicate { itemRecord in
                itemRecord.parentBuilding?.id == buildingID
            }
        }
        return try modelContext.fetchCount(descriptor)
    }

    @MainActor
    private func countItems(forBuildingID: UUID) throws -> Int {
        let buildingIDValue = forBuildingID // Capture for predicate
        let descriptor = FetchDescriptor<Item>(predicate: #Predicate { itemRecord in
            itemRecord.parentBuilding?.id == buildingIDValue
        })
        return try modelContext.fetchCount(descriptor)
    }
    
    @MainActor
    private func fetchAllItems(forBuilding: Building? = nil) throws -> [Item] {
        var descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.name)])
        if let building = forBuilding {
            let buildingID = building.id
            descriptor.predicate = #Predicate { itemRecord in
                itemRecord.parentBuilding?.id == buildingID
            }
        }
        return try modelContext.fetch(descriptor)
    }

    @MainActor
    private func fetchItem(with id: UUID) throws -> Item? {
        let itemIDToFetch = id // Capture for predicate
        let predicate = #Predicate<Item> { itemRecord in
            itemRecord.id == itemIDToFetch
        }
        var fetchDescriptor = FetchDescriptor<Item>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        
        let items = try modelContext.fetch(fetchDescriptor)
        return items.first
    }
}
