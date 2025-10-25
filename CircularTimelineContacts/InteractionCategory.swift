import SwiftUI
import Foundation

/// Categories for classifying interactions with associated colors and metadata
enum InteractionCategory: String, Codable, CaseIterable {
    case meeting = "Meeting"
    case social = "Social"
    case meal = "Meal"
    case sport = "Sport"
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
    case travel = "Travel"
    case entertainment = "Entertainment"
    case education = "Education"
    case family = "Family"
    case date = "Date"
    case hobby = "Hobby"
    case volunteer = "Volunteer"
    case other = "Other"

    var displayName: String {
        rawValue
    }

    /// Default hex color for each category
    var defaultColor: String {
        switch self {
        case .meeting: return "#4CAF50"       // Green
        case .social: return "#2196F3"        // Blue
        case .meal: return "#FF9800"          // Orange
        case .sport: return "#9C27B0"         // Purple
        case .work: return "#F44336"          // Red
        case .personal: return "#00BCD4"      // Cyan
        case .health: return "#E91E63"        // Pink
        case .travel: return "#3F51B5"        // Indigo
        case .entertainment: return "#FFEB3B" // Yellow
        case .education: return "#009688"     // Teal
        case .family: return "#FF5722"        // Deep Orange
        case .date: return "#E91E63"          // Pink
        case .hobby: return "#673AB7"         // Deep Purple
        case .volunteer: return "#8BC34A"     // Light Green
        case .other: return "#9E9E9E"         // Gray
        }
    }

    /// SwiftUI Color computed from hex
    var color: Color {
        Color(hex: defaultColor) ?? .gray
    }

    /// SF Symbol icon name for category
    var iconName: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .social: return "person.3.fill"
        case .meal: return "fork.knife"
        case .sport: return "figure.run"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "cross.fill"
        case .travel: return "airplane"
        case .entertainment: return "tv.fill"
        case .education: return "book.fill"
        case .family: return "house.fill"
        case .date: return "heart.fill"
        case .hobby: return "paintbrush.fill"
        case .volunteer: return "hands.sparkles.fill"
        case .other: return "circle.fill"
        }
    }

    /// Suggested tags for autocomplete
    var suggestedTags: [String] {
        switch self {
        case .meeting:
            return ["standup", "one-on-one", "review", "planning", "brainstorm"]
        case .social:
            return ["hangout", "party", "gathering", "catch-up", "celebration"]
        case .meal:
            return ["breakfast", "brunch", "lunch", "dinner", "coffee", "drinks"]
        case .sport:
            return ["gym", "running", "basketball", "yoga", "tennis", "hiking"]
        case .work:
            return ["project", "deadline", "presentation", "client", "team"]
        case .personal:
            return ["errand", "appointment", "shopping", "chores"]
        case .health:
            return ["doctor", "dentist", "therapy", "checkup", "wellness"]
        case .travel:
            return ["flight", "road-trip", "vacation", "business-trip"]
        case .entertainment:
            return ["movie", "concert", "show", "game", "museum"]
        case .education:
            return ["class", "lecture", "workshop", "study", "exam"]
        case .family:
            return ["kids", "parents", "relatives", "reunion"]
        case .date:
            return ["romantic", "anniversary", "special"]
        case .hobby:
            return ["music", "art", "photography", "coding", "crafts"]
        case .volunteer:
            return ["charity", "community", "service", "donation"]
        case .other:
            return []
        }
    }

    /// Emoji representation
    var emoji: String {
        switch self {
        case .meeting: return "👥"
        case .social: return "🎉"
        case .meal: return "🍽️"
        case .sport: return "⚽"
        case .work: return "💼"
        case .personal: return "👤"
        case .health: return "🏥"
        case .travel: return "✈️"
        case .entertainment: return "🎬"
        case .education: return "📚"
        case .family: return "👨‍👩‍👧‍👦"
        case .date: return "💕"
        case .hobby: return "🎨"
        case .volunteer: return "🤝"
        case .other: return "📌"
        }
    }
}

// MARK: - Category Groups
extension InteractionCategory {
    enum CategoryGroup: String, CaseIterable {
        case professional = "Professional"
        case social = "Social"
        case personal = "Personal"
        case wellness = "Wellness"
        case leisure = "Leisure"

        var categories: [InteractionCategory] {
            switch self {
            case .professional:
                return [.work, .meeting, .education]
            case .social:
                return [.social, .meal, .family, .date]
            case .personal:
                return [.personal, .hobby]
            case .wellness:
                return [.health, .sport]
            case .leisure:
                return [.entertainment, .travel, .volunteer]
            }
        }

        var iconName: String {
            switch self {
            case .professional: return "briefcase"
            case .social: return "person.3"
            case .personal: return "person"
            case .wellness: return "heart"
            case .leisure: return "star"
            }
        }
    }

    var group: CategoryGroup {
        for group in CategoryGroup.allCases {
            if group.categories.contains(self) {
                return group
            }
        }
        return .personal
    }
}

// MARK: - Sorting & Filtering
extension InteractionCategory {
    /// Priority for sorting (higher = more important)
    var sortPriority: Int {
        switch self {
        case .work: return 10
        case .meeting: return 9
        case .health: return 8
        case .education: return 7
        case .family: return 6
        case .date: return 5
        case .social: return 4
        case .meal: return 3
        case .sport: return 2
        case .entertainment, .travel, .hobby, .volunteer: return 1
        case .personal, .other: return 0
        }
    }

    static var sortedByPriority: [InteractionCategory] {
        allCases.sorted { $0.sortPriority > $1.sortPriority }
    }

    static var socialCategories: [InteractionCategory] {
        [.social, .meal, .family, .date, .entertainment]
    }

    static var workRelatedCategories: [InteractionCategory] {
        [.work, .meeting, .education]
    }
}

// MARK: - Analytics Helpers
extension InteractionCategory {
    /// Returns whether this category counts as "quality time" for analytics
    var isQualityTime: Bool {
        switch self {
        case .family, .date, .social, .meal:
            return true
        default:
            return false
        }
    }

    /// Returns whether this category is work-related
    var isWorkRelated: Bool {
        switch self {
        case .work, .meeting:
            return true
        default:
            return false
        }
    }

    /// Returns whether this category is health/wellness related
    var isWellnessRelated: Bool {
        switch self {
        case .health, .sport:
            return true
        default:
            return false
        }
    }
}
