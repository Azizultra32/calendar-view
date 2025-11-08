import SwiftUI

struct AvatarGroupView: View {
    let interaction: TimeInteraction
    let radius: CGFloat
    let containerSize: CGFloat
    let overlapAngle: Double
    let rotation: Angle
    let timeSpan: TimeSpan
    let currentDate: Date
    let isInteractionSelected: Bool
    let selectedParticipantIndex: Int?

    var body: some View {
        ForEach(Array(interaction.participants.enumerated()), id: \.element.id) { index, person in
            let baseAngle = avatarAngle(for: index)
            let rotatedAngle = baseAngle + rotation.radians
            let center = CGPoint(x: containerSize/2, y: containerSize/2)
            let isSelectedParticipant = isInteractionSelected && selectedParticipantIndex == index
            let x = center.x + cos(rotatedAngle) * radius
            let y = center.y + sin(rotatedAngle) * radius

            // Idle vs. snapped styling
            let fillOpacity: Double = isSelectedParticipant ? 1.0 : 0.78
            let strokeOpacity: Double = isSelectedParticipant ? 1.0 : 0.45
            let strokeWidth: CGFloat = isSelectedParticipant ? 3.0 : 1.5
            let scale: CGFloat = isSelectedParticipant ? 1.08 : 1.0
            let shadowRadius: CGFloat = isSelectedParticipant ? 5.0 : 0
            let shadowYOffset: CGFloat = isSelectedParticipant ? 1.4 : 0
            let zIndexValue: Double = isSelectedParticipant ? 10.0 : Double(index) * 0.00001

            Text(person.initial)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(interaction.color.opacity(fillOpacity))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(strokeOpacity), lineWidth: strokeWidth)
                                .shadow(color: interaction.color.opacity(isSelectedParticipant ? 0.4 : 0), radius: shadowRadius)
                        )
                )
                .position(x: x, y: y)
                .scaleEffect(scale)
                .shadow(color: interaction.color.opacity(isSelectedParticipant ? 0.25 : 0), radius: shadowRadius, x: 0, y: shadowYOffset)
                .animation(.timingCurve(0.32, 0.0, 0.18, 1.0, duration: 0.08), value: isSelectedParticipant)
                .zIndex(zIndexValue)
        }
        .frame(width: containerSize, height: containerSize)
    }

    private func avatarAngle(for index: Int) -> Double {
        let baseAngle = angleFromTime(interaction.startTime)
        return baseAngle + Double(index) * overlapAngle * (.pi / 180)
    }

    private func angleFromTime(_ time: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        switch timeSpan {
        case .sixHours:
            // Get the current 6-hour window
            let windowStart = getWindowStartHour()
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 6.0) * 2 * .pi - .pi/2
        case .twelveHours:
            // Get the current 12-hour window
            let windowStart = getWindowStartHour()
            let hoursFromStart = Double(hour - windowStart) + Double(minute) / 60.0
            return (hoursFromStart / 12.0) * 2 * .pi - .pi/2
        case .twentyFourHours:
            let totalMinutes = Double(hour * 60 + minute)
            return (totalMinutes / (24 * 60)) * 2 * .pi - .pi/2
        case .threeDays, .sevenDays:
            // For multi-day views, we need to calculate based on the full span
            let totalMinutes = Double(hour * 60 + minute)
            let spanMinutes = Double(timeSpan.hours * 60)
            return (totalMinutes / spanMinutes) * 2 * .pi - .pi/2
        }
    }

    private func getWindowStartHour() -> Int {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentDate)

        switch timeSpan {
        case .sixHours:
            return (currentHour / 6) * 6
        case .twelveHours:
            return (currentHour / 12) * 12
        default:
            return 0
        }
    }
}
