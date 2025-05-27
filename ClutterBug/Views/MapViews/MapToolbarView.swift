import SwiftUI

// MARK: - Map Toolbar Component
struct MapToolbarView: View {
    @ObservedObject var mapState: MapViewState
    let building: Building?
    let viewSize: CGSize
    
    var body: some View {
        VStack {
            toolbarButtons
            
            if mapState.showMeasurements {
                HStack {
                    ScaleBar(zoom: mapState.zoom * mapState.magnifyBy)
                        .padding(.leading, 8)
                    Spacer()
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var toolbarButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                measurementButton
                gridButton
                dimensionsButton
                measurementModeButton
                shapeEditorButton
                shapeListButton
                resetViewButton
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Individual Buttons
    
    private var measurementButton: some View {
        Button(action: mapState.toggleMeasurements) {
            Image(systemName: mapState.showMeasurements ? "ruler.fill" : "ruler")
                .foregroundColor(.blue)
                .font(.system(size: 14))
                .padding(4)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
        }
    }
    
    private var gridButton: some View {
        Button(action: mapState.toggleGrid) {
            Image(systemName: mapState.showGrid ? "grid.circle.fill" : "grid.circle")
                .foregroundColor(.blue)
                .font(.system(size: 14))
                .padding(4)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
        }
    }
    
    private var dimensionsButton: some View {
        Button(action: mapState.toggleDimensions) {
            Image(systemName: "rectangle.and.text.magnifyingglass")
                .foregroundColor(mapState.showDimensions ? .blue : .gray)
                .font(.system(size: 14))
                .padding(4)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
        }
    }
    
    private var measurementModeButton: some View {
        Button(action: mapState.toggleMeasurementMode) {
            Image(systemName: "plus.magnifyingglass")
                .foregroundColor(mapState.measurementMode ? .red : .gray)
                .font(.system(size: 14))
                .padding(4)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
        }
    }
    
    private var shapeEditorButton: some View {
        Button(action: mapState.toggleShapeEditor) {
            Image(systemName: "square.and.pencil")
                .foregroundColor(mapState.showShapeEditor ? .green : .gray)
                .font(.system(size: 14))
                .padding(4)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private var shapeListButton: some View {
        if !mapState.placedShapes.isEmpty {
            Button(action: mapState.toggleShapeList) {
                HStack(spacing: 2) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12))
                    Text("\(mapState.placedShapes.count)")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.purple)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.8))
                .clipShape(Capsule())
            }
        }
    }
    
    private var resetViewButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                mapState.resetView(for: building, in: viewSize)
            }
        }) {
            Image(systemName: "house")
                .foregroundColor(.orange)
                .font(.system(size: 14))
                .padding(4)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
        }
    }
}

// MARK: - Scale Bar Component
struct ScaleBar: View {
    let zoom: CGFloat
    
    var body: some View {
        let scaleLength: CGFloat = 100
        let mapUnits = scaleLength / zoom
        let roundedUnits = getRoundedScale(mapUnits)
        let displayLength = roundedUnits * zoom
        
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: displayLength/2, height: 3)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: displayLength/2, height: 3)
                    .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
            }
            .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
            
            Text("\(Int(roundedUnits)) ft")
                .font(.caption)
                .foregroundColor(.black)
        }
        .padding(8)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }
    
    private func getRoundedScale(_ value: CGFloat) -> CGFloat {
        let magnitude = pow(10, floor(log10(value)))
        let normalized = value / magnitude
        
        if normalized <= 1 { return magnitude }
        else if normalized <= 2 { return 2 * magnitude }
        else if normalized <= 5 { return 5 * magnitude }
        else { return 10 * magnitude }
    }
}
