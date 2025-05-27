import SwiftUI
import SwiftData

//v16 - Refactored into modular coordinator pattern with separated concerns

// MARK: - Main MapView Coordinator
struct MapView: View {
    // External Interface - KEEP SAME for compatibility
    var buildingToDisplay: Building?
    var switchToListView: () -> Void
    
    // Shared State - passed down to child components
    @StateObject private var mapState = MapViewState()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.gray.opacity(0.1)
                
                // Main building canvas with zoom/pan
                BuildingCanvasView(
                    building: buildingToDisplay,
                    mapState: mapState,
                    viewSize: geometry.size
                )
                
                // Top toolbar controls
                MapToolbarView(
                    mapState: mapState,
                    building: buildingToDisplay,
                    viewSize: geometry.size
                )
                
                // Shape management overlay
                ShapeManagerView(
                    mapState: mapState,
                    building: buildingToDisplay,
                    viewSize: geometry.size
                )
                
                // Measurement tools overlay
                MeasurementToolsView(mapState: mapState)
            }
            .onAppear {
                mapState.resetView(for: buildingToDisplay, in: geometry.size)
            }
            .onChange(of: buildingToDisplay?.id) { _, _ in
                mapState.resetView(for: buildingToDisplay, in: geometry.size)
                mapState.clearShapes()
            }
        }
    }
}

// MARK: - Shared State Management
class MapViewState: ObservableObject {
    // Pan and Zoom
    @Published var zoom: CGFloat = 1.0
    @Published var panOffset: CGSize = .zero
    @Published var dragOffset: CGSize = .zero
    @Published var magnifyBy: CGFloat = 1.0
    
    // Tool States
    @Published var showMeasurements: Bool = true
    @Published var showGrid: Bool = false
    @Published var showDimensions: Bool = true
    @Published var measurementMode: Bool = false
    @Published var showShapeEditor: Bool = false
    @Published var showShapeList: Bool = false
    
    // Measurement State
    @Published var measurementStart: CGPoint?
    @Published var measurementEnd: CGPoint?
    
    // Shape State
    @Published var placedShapes: [PlacedShape] = []
    @Published var selectedShape: PlacedShape?
    @Published var isDraggingShape: Bool = false
    
    // Edit State
    @Published var editingShapeDimensions: PlacedShape?
    @Published var showDeleteConfirmation: Bool = false
    @Published var shapeToDelete: PlacedShape?
    @Published var tempLabelText: String = ""
    @Published var tempWidth: String = ""
    @Published var tempLength: String = ""
    
    // MARK: - Actions
    
    func resetView(for building: Building?, in viewSize: CGSize) {
        guard let building = building,
              let mapW = building.mapWidth,
              let mapH = building.mapHeight else {
            zoom = 1.0
            panOffset = .zero
            return
        }
        
        let padding: CGFloat = 50
        let scaleX = (viewSize.width - padding * 2) / mapW
        let scaleY = (viewSize.height - padding * 2) / mapH
        zoom = min(scaleX, scaleY, 2.0)
        panOffset = .zero
    }
    
    func clearShapes() {
        placedShapes.removeAll()
        selectedShape = nil
    }
    
    func addShape(_ shape: PlacedShape) {
        placedShapes.append(shape)
        selectedShape = shape
    }
    
    func updateShape(id: UUID, position: CGPoint? = nil, label: String? = nil, width: Double? = nil, length: Double? = nil) {
        guard let index = placedShapes.firstIndex(where: { $0.id == id }) else { return }
        
        if let position = position {
            placedShapes[index].position = position
        }
        if let label = label {
            placedShapes[index].label = label
        }
        if let width = width {
            placedShapes[index].width = width
        }
        if let length = length {
            placedShapes[index].length = length
        }
        // Size is now computed automatically from width/length and building scale
    }
    
    func deleteShape(id: UUID) {
        placedShapes.removeAll { $0.id == id }
        if selectedShape?.id == id {
            selectedShape = nil
        }
    }
    
    func selectShape(_ shape: PlacedShape) {
        selectedShape = shape
    }
    
    func clearSelection() {
        selectedShape = nil
    }
    
    func toggleMeasurements() {
        showMeasurements.toggle()
    }
    
    func toggleGrid() {
        showGrid.toggle()
    }
    
    func toggleDimensions() {
        showDimensions.toggle()
    }
    
    func toggleMeasurementMode() {
        measurementMode.toggle()
        if !measurementMode {
            measurementStart = nil
            measurementEnd = nil
        }
    }
    
    func toggleShapeEditor() {
        showShapeEditor.toggle()
    }
    
    func toggleShapeList() {
        showShapeList.toggle()
    }
}
