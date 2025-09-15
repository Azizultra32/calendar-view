import SwiftUI

struct HourMarkerView: View {
    let hour: Int
    let radius: CGFloat
    let containerSize: CGFloat
    let rotation: Angle
    let timeSpan: TimeSpan
    
    private var adjustedHour: Double {
        switch timeSpan {
        case .sixHours, .twelveHours:
            return Double(hour % timeSpan.hours)
        default:
            return Double(hour)
        }
    }
    
    private var position: CGPoint {
        let totalHours = Double(timeSpan.hours)
        let hourAngleDegrees = (adjustedHour / totalHours) * 360.0
        let hourAngleRadians = hourAngleDegrees * (.pi / 180)
        let adjustedAngle = hourAngleRadians - .pi/2
        let finalAngle = adjustedAngle + rotation.radians
        
        let center = CGPoint(x: containerSize/2, y: containerSize/2)
        let markerRadius = radius + 20
        let x = center.x + cos(finalAngle) * markerRadius
        let y = center.y + sin(finalAngle) * markerRadius
        
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {
        Text(formatHour(hour, for: timeSpan))
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.gray)
            .position(position)
            .frame(width: containerSize, height: containerSize)
    }
    
    private func formatHour(_ hour: Int, for timeSpan: TimeSpan) -> String {
        switch timeSpan {
        case .sixHours, .twelveHours, .twentyFourHours:
            if hour == 0 { return "12AM" }
            if hour < 12 { return "\(hour)AM" }
            if hour == 12 { return "12PM" }
            return "\(hour - 12)PM"
        case .sevenDays:
            let day = hour / 24
            let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return dayNames[day % 7]
        }
    }
}