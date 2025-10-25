import SwiftUI
import SwiftData
import CoreLocation
import Foundation

/// Represents a reusable location with optional coordinates and metadata
@Model
final class Location {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Basic Info
    var name: String
    var address: String?

    // MARK: - Coordinates
    var latitude: Double?
    var longitude: Double?

    // MARK: - Metadata
    var placeType: String?  // "Restaurant", "Office", "Home", "Park", "Gym", etc.
    var notes: String?
    var isFavorite: Bool
    var phoneNumber: String?
    var website: String?

    // MARK: - Categories & Tags
    var category: LocationCategory
    var tags: [String]

    // MARK: - Relationships
    @Relationship(inverse: \Interaction.location)
    var interactions: [Interaction]

    // MARK: - Computed Properties
    var visitCount: Int {
        interactions.count
    }

    var lastVisitDate: Date? {
        interactions.max(by: { $0.startTime < $1.startTime })?.startTime
    }

    var totalTimeSpent: TimeInterval {
        interactions.reduce(0) { total, interaction in
            total + interaction.duration
        }
    }

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var formattedAddress: String {
        address ?? name
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        name: String,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        category: LocationCategory = .other,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.isFavorite = isFavorite
        self.tags = []
        self.interactions = []
    }

    // MARK: - Methods
    func updateTimestamp() {
        self.updatedAt = Date()
    }

    func updateCoordinates(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        updateTimestamp()
    }

    func distance(from otherLocation: Location) -> Double? {
        guard let coord1 = coordinate, let coord2 = otherLocation.coordinate else {
            return nil
        }

        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)

        return location1.distance(from: location2)  // Returns meters
    }

    func distanceInMiles(from otherLocation: Location) -> Double? {
        guard let meters = distance(from: otherLocation) else { return nil }
        return meters / 1609.34
    }

    func distanceInKilometers(from otherLocation: Location) -> Double? {
        guard let meters = distance(from: otherLocation) else { return nil }
        return meters / 1000.0
    }
}

// MARK: - Location Category
enum LocationCategory: String, Codable, CaseIterable {
    case home = "Home"
    case work = "Work"
    case restaurant = "Restaurant"
    case cafe = "Cafe"
    case bar = "Bar"
    case gym = "Gym"
    case park = "Park"
    case office = "Office"
    case school = "School"
    case hospital = "Hospital"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case sports = "Sports"
    case travel = "Travel"
    case outdoor = "Outdoor"
    case other = "Other"

    var displayName: String {
        rawValue
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .bar: return "wineglass.fill"
        case .gym: return "figure.run"
        case .park: return "tree.fill"
        case .office: return "building.2.fill"
        case .school: return "book.fill"
        case .hospital: return "cross.case.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .sports: return "sportscourt.fill"
        case .travel: return "airplane"
        case .outdoor: return "mountain.2.fill"
        case .other: return "mappin.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .home: return .orange
        case .work: return .blue
        case .restaurant: return .red
        case .cafe: return .brown
        case .bar: return .purple
        case .gym: return .green
        case .park: return .green
        case .office: return .blue
        case .school: return .indigo
        case .hospital: return .red
        case .shopping: return .pink
        case .entertainment: return .yellow
        case .sports: return .cyan
        case .travel: return .teal
        case .outdoor: return .mint
        case .other: return .gray
        }
    }

    var emoji: String {
        switch self {
        case .home: return "🏠"
        case .work: return "🏢"
        case .restaurant: return "🍽️"
        case .cafe: return "☕"
        case .bar: return "🍷"
        case .gym: return "💪"
        case .park: return "🌳"
        case .office: return "🏢"
        case .school: return "🎓"
        case .hospital: return "🏥"
        case .shopping: return "🛍️"
        case .entertainment: return "🎭"
        case .sports: return "⚽"
        case .travel: return "✈️"
        case .outdoor: return "⛰️"
        case .other: return "📍"
        }
    }
}

// MARK: - Formatting Extensions
extension Location {
    var displayString: String {
        if let address = address {
            return "\(name)\n\(address)"
        }
        return name
    }

    var oneLineDisplay: String {
        if let address = address {
            return "\(name), \(address)"
        }
        return name
    }

    var mapURL: URL? {
        if let lat = latitude, let lon = longitude {
            // Apple Maps URL
            let urlString = "http://maps.apple.com/?q=\(lat),\(lon)"
            return URL(string: urlString)
        } else if let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            // Search by name
            let urlString = "http://maps.apple.com/?q=\(encodedName)"
            return URL(string: urlString)
        }
        return nil
    }

    var googleMapsURL: URL? {
        if let lat = latitude, let lon = longitude {
            let urlString = "https://www.google.com/maps/search/?api=1&query=\(lat),\(lon)"
            return URL(string: urlString)
        } else if let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let urlString = "https://www.google.com/maps/search/?api=1&query=\(encodedName)"
            return URL(string: urlString)
        }
        return nil
    }
}
