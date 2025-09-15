import SwiftUI

struct InteractionArcView: View {
    let interaction: TimeInteraction
    let radius: CGFloat
    let center: CGPoint
    let timeSpan: TimeSpan
    
    var body: some View {
        let startAngle = angleFromTime(interaction.startTime)
        let endAngle = angleFromTime(interaction.endTime)
        
        Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: Angle(radians: startAngle),
                endAngle: Angle(radians: endAngle),
                clockwise: false
            )
        }
        .stroke(interaction.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
    }
    
    private func angleFromTime(_ time: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        switch timeSpan {
        case .sixHours:
            // Get the current 6-hour window
            let currentHour = calendar.component(.hour, from: Date())
            let windowStart = (currentHour / 6) * 6
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 6.0) * 2 * .pi - .pi/2
        case .twelveHours:
            // Get the current 12-hour window
            let currentHour = calendar.component(.hour, from: Date())
            let windowStart = (currentHour / 12) * 12
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 12.0) * 2 * .pi - .pi/2
        case .twentyFourHours:
            let totalMinutes = Double(hour * 60 + minute)
            return (totalMinutes / (24 * 60)) * 2 * .pi - .pi/2
        case .sevenDays:
            // For multi-day views, we need to calculate based on the full span
            let totalMinutes = Double(hour * 60 + minute)
            let spanMinutes = Double(timeSpan.hours * 60)
            return (totalMinutes / spanMinutes) * 2 * .pi - .pi/2
        }
    }
}