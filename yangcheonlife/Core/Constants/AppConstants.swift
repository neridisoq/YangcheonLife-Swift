import Foundation
import SwiftUI

// MARK: - 앱 전반 상수 정의

struct AppConstants {
    
    // MARK: - 앱 정보
    struct App {
        static let name = "양천고 라이프"
        static let version = "4.0"
        static let bundleIdentifier = "com.yangcheon.life"
    }
    
    // MARK: - API 관련
    struct API {
        static let baseURL = "https://comsi.helgisnw.me"
        static let mealURL = "https://meal.helgisnw.com"
        
        /// 시간표 API URL 생성
        static func scheduleURL(grade: Int, classNumber: Int) -> String {
            return "\(baseURL)/\(grade)/\(classNumber)"
        }
    }
    
    // MARK: - UserDefaults 키
    struct UserDefaultsKeys {
        static let defaultGrade = "defaultGrade"
        static let defaultClass = "defaultClass"
        static let notificationsEnabled = "notificationsEnabled"
        static let physicalEducationAlertEnabled = "physicalEducationAlertEnabled"
        static let physicalEducationAlertTime = "physicalEducationAlertTime"
        static let cellBackgroundColor = "cellBackgroundColor"
        static let initialSetupCompleted = "initialSetupCompleted"
        static let wifiSuggestionEnabled = "wifiSuggestionEnabled"
        static let lastSeenUpdateVersion = "lastSeenUpdateVersion"
        
        // 시간표 저장소 키
        static let scheduleDataStore = "schedule_data_store"
        static let scheduleCompareStore = "schedule_compare_store"
        
        // 탐구과목 선택 키 생성
        static func selectedSubjectKey(for subject: String) -> String {
            return "selected\(subject)Subject"
        }
    }
    
    // MARK: - 학교 정보
    struct School {
        static let grades = 1...3
        static let classes = 1...11
        static let weekdays = ["월", "화", "수", "목", "금"]
        static let totalPeriods = 7
        
        // 교시별 시간 문자열
        static let periodTimeStrings = [
            ("08:20", "09:10"), ("09:20", "10:10"), ("10:20", "11:10"), ("11:20", "12:10"),
            ("13:10", "14:00"), ("14:10", "15:00"), ("15:10", "16:00")
        ]
    }
    
    // MARK: - 알림 관련
    struct Notification {
        static let categoryIdentifier = "SCHEDULE_CATEGORY"
        static let beforeClassMinutes = 10  // 수업 10분 전 알림
        
        /// 알림 식별자 생성
        static func scheduleIdentifier(grade: Int, classNumber: Int, weekday: Int, period: Int) -> String {
            return "schedule-g\(grade)-c\(classNumber)-d\(weekday)-p\(period)"
        }
        
        static func physicalEducationIdentifier(weekday: Int) -> String {
            return "pe-alert-\(weekday)"
        }
    }
    
    // MARK: - 위젯 관련
    struct Widget {
        static let groupIdentifier = "group.com.yangcheon.life"
        static let refreshInterval: TimeInterval = 600 // 10분
    }
    
    // MARK: - UI 관련
    struct UI {
        // 기본 색상
        static let primaryColor = Color.blue
        static let defaultCellBackgroundColor = Color.yellow.opacity(0.3)
        
        // 폰트 크기
        static let headerFontSize: CGFloat = 18
        static let bodyFontSize: CGFloat = 16
        static let captionFontSize: CGFloat = 14
        static let smallFontSize: CGFloat = 12
        
        // 레이아웃
        static let defaultPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 10
    }
    
    // MARK: - 외부 링크
    struct ExternalLinks {
        static let schoolWebsite = "https://yangcheon.sen.hs.kr"
        static let privacyPolicy = "https://yangcheon.sen.hs.kr/dggb/module/policy/selectPolicyDetail.do?policyTypeCode=PLC002&menuNo=75574"
        static let developerInstagram = "https://instagram.com/neridisoq_"
        static let supportEmail = "neridisoq@icloud.com"
    }
}

// MARK: - 로컬라이제이션 키
struct LocalizationKeys {
    static let timeTable = "TimeTable"
    static let meal = "Meal"
    static let settings = "Settings"
    static let grade = "Grade"
    static let classKey = "Class"
    static let gradeP = "GradeP"
    static let classP = "ClassP"
    static let period = "period"
    static let monday = "Mon"
    static let tuesday = "Tue"
    static let wednesday = "Wed"
    static let thursday = "Thu"
    static let friday = "Fri"
    static let alert = "Alert"
    static let alertSettings = "Alert Settings"
    static let classSettings = "ClassSettings"
    static let colorPicker = "ColorPicker"
    static let link = "Link"
    static let support = "Support"
    static let privacyPolicy = "Privacy Policy"
    static let gotoSchoolWeb = "Goto School Web"
    static let supportto = "Supportto"
    static let developerInstagram = "개발자 인스타그램"
}