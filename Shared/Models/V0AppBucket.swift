import Foundation

public enum V0AppBucket: String, CaseIterable, Codable {
    case social
    case games
    case productivity
    case foodDelivery
    case entertainmentStreaming
    case shopping
    case communication
    case finance
    case sports
    case news
    case education
    case healthFitness
    case travel
    case utilities
    case other

    public var title: String {
        switch self {
        case .social: return "Social"
        case .games: return "Games"
        case .productivity: return "Productivity"
        case .foodDelivery: return "Food/Delivery"
        case .entertainmentStreaming: return "Entertainment/Streaming"
        case .shopping: return "Shopping"
        case .communication: return "Communication"
        case .finance: return "Finance"
        case .sports: return "Sports"
        case .news: return "News"
        case .education: return "Education"
        case .healthFitness: return "Health/Fitness"
        case .travel: return "Travel"
        case .utilities: return "Utilities"
        case .other: return "Other"
        }
    }
}
