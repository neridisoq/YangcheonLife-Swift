import Foundation

public struct MealInfo: Codable {
    public let mealType: MealType
    public let menuText: String
    public let calInfo: String
    
    public init(mealType: MealType, menuText: String, calInfo: String) {
        self.mealType = mealType
        self.menuText = menuText
        self.calInfo = calInfo
    }
}

public enum MealType: Int, Codable {
    case breakfast = 1
    case lunch = 2
    case dinner = 3
    
    public var name: String {
        switch self {
        case .breakfast: return "조식"
        case .lunch: return "중식"
        case .dinner: return "석식"
        }
    }
}