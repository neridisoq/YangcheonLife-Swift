import SwiftUI
import UIKit

// MARK: - Color 확장
extension Color {
    
    /// UIColor를 저장하고 불러오기 위한 메서드들
    func toUIColor() -> UIColor {
        return UIColor(self)
    }
    
    /// UserDefaults에 색상 저장
    func saveToUserDefaults(key: String) {
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: self.toUIColor(), requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: key)
        }
    }
    
    /// UserDefaults에서 색상 불러오기
    static func loadFromUserDefaults(key: String, defaultColor: Color = .clear) -> Color {
        guard let colorData = UserDefaults.standard.data(forKey: key),
              let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) else {
            return defaultColor
        }
        return Color(uiColor)
    }
    
    /// 앱 테마 색상들
    static let appPrimary = Color.blue
    static let appSecondary = Color.gray
    static let appAccent = Color.orange
    
    /// 시간표 관련 색상들
    static let currentPeriodBackground = Color.yellow.opacity(0.3)
    static let nextPeriodBackground = Color.blue.opacity(0.1)
    static let headerBackground = Color.gray.opacity(0.3)
    
    /// 상태별 색상들
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red
    static let infoColor = Color.blue
    
    /// 투명도 적용
    func withOpacity(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }
    
    /// 밝기 조절
    func lighter(by percentage: CGFloat = 30.0) -> Color {
        return self.adjustBrightness(by: abs(percentage) )
    }
    
    func darker(by percentage: CGFloat = 30.0) -> Color {
        return self.adjustBrightness(by: -1 * abs(percentage) )
    }
    
    private func adjustBrightness(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness += (percentage / 100.0)
            brightness = max(min(brightness, 1.0), 0.0)
            return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
        }
        
        return self
    }
}

// MARK: - UIColor 확장
extension UIColor {
    
    /// 16진수 색상 코드로 UIColor 생성
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
    
    /// UIColor를 16진수 문자열로 변환
    func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
    
    /// 명도에 따라 텍스트 색상 결정 (검은색 또는 흰색)
    var contrastColor: UIColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5 ? .black : .white
    }
}