import SwiftUI

// MARK: - Measurement Tools Component
struct MeasurementToolsView: View {
    @ObservedObject var mapState: MapViewState
    
    var body: some View {
        // Measurement line overlay
        if let start = mapState.measurementStart,
           let end = mapState.measurementEnd {
            MeasurementLineView(
                start: start,
                end: end,
                zoom: mapState.zoom * mapState.magnifyBy
            )
        }
    }
}

// MARK: - Measurement Line
struct MeasurementLineView: View {
    let start: CGPoint
    let end: CGPoint
    let zoom: CGFloat
    
    var body: some View {
        let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2)) / zoom
        let midPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        
        ZStack {
            // Measurement line
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(Color.red, lineWidth: 2)
            
            // Start and end points
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .position(start)
            
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .position(end)
            
            // Distance label
            Text("\(Int(distance)) ft")
                .font(.caption)
                .padding(4)
                .background(Color.white.opacity(0.9))
                .cornerRadius(4)
                .position(CGPoint(x: midPoint.x, y: midPoint.y - 20))
        }
    }
}
