import Foundation
import SwiftUI

// MARK: - 앱 전반 상수 정의

public struct AppConstants {
    
    // MARK: - 앱 정보
    struct App {
        static let name = "양천고 라이프"
        static let version = "4.1"
        static let bundleIdentifier = "com.helgisnw.yangcheonlife"
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
    public struct UserDefaultsKeys {
        public static let defaultGrade = "defaultGrade"
        public static let defaultClass = "defaultClass"
        public static let notificationsEnabled = "notificationsEnabled"
        public static let physicalEducationAlertEnabled = "physicalEducationAlertEnabled"
        public static let physicalEducationAlertTime = "physicalEducationAlertTime"
        public static let cellBackgroundColor = "cellBackgroundColor"
        public static let initialSetupCompleted = "initialSetupCompleted"
        public static let wifiSuggestionEnabled = "wifiSuggestionEnabled"
        public static let lastSeenUpdateVersion = "lastSeenUpdateVersion"
        
        // 시간표 저장소 키
        public static let scheduleDataStore = "schedule_data_store"
        public static let scheduleCompareStore = "schedule_compare_store"
        
        // 탐구과목 선택 키 생성
        public static func selectedSubjectKey(for subject: String) -> String {
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
        static let groupIdentifier = "group.com.helgisnw.yangcheonlife"
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
    static let developerInstagram = "Developer Instagram"
    static let initialSetup = "Initial Setup"
    
    // 추가된 키들
    static let liveActivity = "Live Activity"
    static let liveActivityDisplay = "Live Activity Display"
    static let liveActivityDescription = "Live Activity Description"
    static let running = "Running"
    static let start = "Start"
    static let stop = "Stop"
    static let iosVersionRequired = "iOS Version Required"
    static let basicSettings = "Basic Settings"
    static let gradeClassSettings = "Grade Class Settings"
    static let subjectSelection = "Subject Selection"
    static let wifiConnection = "WiFi Connection"
    static let wifiSuggestion = "WiFi Suggestion"
    static let scheduleCellColor = "Schedule Cell Color"
    static let notificationSettings = "Notification Settings"
    static let classNotification = "Class Notification"
    static let peNotification = "PE Notification"
    static let peNotificationTime = "PE Notification Time"
    static let testNotification = "Test Notification"
    static let appInfo = "App Info"
    static let version = "Version"
    static let appName = "App Name"
    static let developer = "Developer"
    static let developerName = "Developer Name"
    static let schoolWebsite = "School Website"
    static let sendEmailToDeveloper = "Send Email to Developer"
    static let advancedSettings = "Advanced Settings"
    static let confirm = "Confirm"
    static let allNotificationsDisabled = "All Notifications Disabled"
    static let notificationPermissionRequired = "Notification Permission Required"
    static let dataManagement = "Data Management"
    static let resetAllSettings = "Reset All Settings"
    static let exportSettings = "Export Settings"
    static let importSettings = "Import Settings"
    static let cacheManagement = "Cache Management"
    static let clearScheduleCache = "Clear Schedule Cache"
    static let removeAllNotifications = "Remove All Notifications"
    static let debugInfo = "Debug Info"
    static let currentScheduleData = "Current Schedule Data"
    static let exists = "Exists"
    static let none = "None"
    static let notificationPermission = "Notification Permission"
    static let allowed = "Allowed"
    static let denied = "Denied"
    static let liveActivityStatus = "Live Activity Status"
    static let stopped = "Stopped"
    static let ios18Required = "iOS 18+ Required"
    static let refreshNotificationPermission = "Refresh Notification Permission"
    static let liveActivityTest = "Live Activity Test"
    static let startLiveActivityTest = "Start Live Activity Test"
    static let stopLiveActivityTest = "Stop Live Activity Test"
    static let checkLiveActivityPermission = "Check Live Activity Permission"
    static let resetAllSettingsTitle = "Reset All Settings Title"
    static let resetAllSettingsMessage = "Reset All Settings Message"
    static let reset = "Reset"
    static let settingsData = "Settings Data"
    static let copy = "Copy"
    static let ok = "OK"
    static let settingsDataGenerated = "Settings Data Generated"
    static let success = "Success"
    static let importSuccessMessage = "Import Success Message"
    static let failed = "Failed"
    static let importFailedMessage = "Import Failed Message"
    static let importSettingsData = "Import Settings Data"
    static let importInstructions = "Import Instructions"
    static let jsonData = "JSON Data"
    static let cancel = "Cancel"
    static let `import` = "Import"
    static let currentInClass = "Current In Class"
    static let breakTimeNext = "Break Time Next"
    static let lunchTimeNext = "Lunch Time Next"
    static let preClassTime = "Pre Class Time"
    static let classroom = "Classroom"
    static let connectWiFi = "Connect WiFi"
    static let currentDisplay = "Current Display"
    static let setNotificationForThisSchedule = "Set Notification for This Schedule"
    static let loadingMealInfo = "Loading Meal Info"
    static let mealLoadingFailed = "Meal Loading Failed"
    static let invalidMealURL = "Invalid Meal URL"
    static let wifiConnectionResult = "WiFi Connection Result"
    static let welcomeMessage = "Welcome Message"
    static let setupDescription = "Setup Description"
    static let selectGradeClass = "Select Grade Class"
    static let gradeClassRequired = "Grade Class Required"
    static let gradeX = "Grade X"
    static let classX = "Class X"
    static let notificationSetup = "Notification Setup"
    static let notificationQuestion = "Notification Question"
    static let receiveClassNotifications = "Receive Class Notifications"
    static let notificationInfo = "Notification Info"
    static let settingsLater = "Settings Later"
    static let previous = "Previous"
    static let next = "Next"
    static let complete = "Complete"
    static let schoolWiFiConnection = "School WiFi Connection"
    static let gradeXClassroomWiFi = "Grade X Classroom WiFi"
    static let gradeXClassY = "Grade X Class Y"
    static let connect = "Connect"
    static let specialRoomWiFi = "Special Room WiFi"
    static let locationPermissionRequired = "Location Permission Required"
    static let locationPermissionDescription = "Location Permission Description"
    static let wifiHiddenSSID = "WiFi Hidden SSID"
    static let gradeSSIDFormat = "Grade SSID Format"
    static let passwordFormat = "Password Format"
    static let passwordExample = "Password Example"
    static let specialRoomInfo = "Special Room Info"
    static let specialRoomReference = "Special Room Reference"
    static let info = "Info"
    static let locationPermissionRequiredForWiFi = "Location Permission Required For WiFi"
}
