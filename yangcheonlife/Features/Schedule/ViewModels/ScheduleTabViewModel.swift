// ScheduleTabViewModel.swift - 시간표 탭 뷰모델
import SwiftUI
import Combine

class ScheduleTabViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var displayGrade: Int = 1
    @Published var displayClass: Int = 1
    @Published var currentClassInfo: ScheduleItem?
    @Published var suggestedWiFiConnection: WiFiConnectionType?
    @Published var cellBackgroundColor: Color = .currentPeriodBackground
    @Published var isWifiSuggestionEnabled: Bool = true
    
    // MARK: - Computed Properties
    var actualGrade: Int {
        get { UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade) }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.UserDefaultsKeys.defaultGrade) }
    }
    
    var actualClass: Int {
        get { UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass) }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.UserDefaultsKeys.defaultClass) }
    }
    
    /// 현재 표시 중인 학년/반과 실제 알림 설정이 다른지 확인
    var showDifferentGradeClassInfo: Bool {
        return displayGrade != actualGrade || displayClass != actualClass
    }
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let wifiService = WiFiService.shared
    
    // MARK: - Timer for periodic updates
    lazy var timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    // MARK: - Initialization
    init() {
        setupInitialValues()
        loadCellBackgroundColor()
    }
    
    // MARK: - Public Methods
    
    /// 초기값 설정
    func setupInitialValues() {
        let savedGrade = actualGrade
        let savedClass = actualClass
        
        displayGrade = savedGrade > 0 ? savedGrade : 1
        displayClass = savedClass > 0 ? savedClass : 1
        isWifiSuggestionEnabled = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.wifiSuggestionEnabled) as? Bool ?? true
    }
    
    /// 현재 수업 정보 업데이트
    func updateCurrentClassInfo(scheduleData: ScheduleData?) {
        guard let scheduleData = scheduleData else {
            currentClassInfo = nil
            suggestedWiFiConnection = nil
            return
        }
        
        let now = Date()
        let weekdayIndex = TimeUtility.getCurrentWeekdayIndex(at: now)
        
        // 주말이면 정보 숨김
        guard weekdayIndex >= 0 else {
            currentClassInfo = nil
            suggestedWiFiConnection = nil
            return
        }
        
        let currentStatus = TimeUtility.getCurrentPeriodStatus(at: now)
        
        switch currentStatus {
        case .inClass(let period), .preClass(let period):
            // 현재 또는 다음 수업 정보 가져오기
            if let classInfo = scheduleData.getClassInfo(weekday: weekdayIndex, period: period) {
                currentClassInfo = classInfo
                suggestedWiFiConnection = wifiService.getSuggestedWiFiConnection(for: classInfo)
            } else {
                currentClassInfo = nil
                suggestedWiFiConnection = nil
            }
            
        default:
            currentClassInfo = nil
            suggestedWiFiConnection = nil
        }
    }
    
    /// 타이머 시작
    func startTimer() {
        // Timer는 이미 lazy로 초기화되므로 별도 시작 불필요
    }
    
    /// 셀 배경색 로드
    func loadCellBackgroundColor() {
        cellBackgroundColor = Color.loadFromUserDefaults(
            key: AppConstants.UserDefaultsKeys.cellBackgroundColor,
            defaultColor: .currentPeriodBackground
        )
    }
    
    /// 셀 배경색 저장
    func saveCellBackgroundColor(_ color: Color) {
        color.saveToUserDefaults(key: AppConstants.UserDefaultsKeys.cellBackgroundColor)
        cellBackgroundColor = color
    }
    
    /// 현재 교시인지 확인
    func isCurrentPeriod(weekday: Int, period: Int) -> Bool {
        let now = Date()
        let currentWeekday = TimeUtility.getCurrentWeekdayIndex(at: now)
        
        // 현재 요일이 아니면 false
        guard currentWeekday == weekday else { return false }
        
        let currentStatus = TimeUtility.getCurrentPeriodStatus(at: now)
        
        switch currentStatus {
        case .inClass(let currentPeriod):
            return period == currentPeriod
        case .preClass(let nextPeriod), .breakTime(let nextPeriod):
            return period == nextPeriod
        default:
            return false
        }
    }
    
    /// 특정 과목의 표시명 가져오기 (탐구과목 치환 포함)
    func getDisplaySubject(for scheduleItem: ScheduleItem) -> String {
        guard scheduleItem.subject.contains("반") else {
            return scheduleItem.subject
        }
        
        let customKey = AppConstants.UserDefaultsKeys.selectedSubjectKey(for: scheduleItem.subject)
        
        if let selectedSubject = userDefaults.string(forKey: customKey),
           selectedSubject != "선택 없음" && selectedSubject != scheduleItem.subject {
            
            let components = selectedSubject.components(separatedBy: "/")
            return components.first ?? scheduleItem.subject
        }
        
        return scheduleItem.subject
    }
    
    /// 특정 과목의 표시 교실 가져오기 (탐구과목 치환 포함)
    func getDisplayClassroom(for scheduleItem: ScheduleItem) -> String {
        guard scheduleItem.subject.contains("반") else {
            return scheduleItem.classroom
        }
        
        let customKey = AppConstants.UserDefaultsKeys.selectedSubjectKey(for: scheduleItem.subject)
        
        if let selectedSubject = userDefaults.string(forKey: customKey),
           selectedSubject != "선택 없음" && selectedSubject != scheduleItem.subject {
            
            let components = selectedSubject.components(separatedBy: "/")
            return components.count == 2 ? components[1] : scheduleItem.classroom
        }
        
        return scheduleItem.classroom
    }
}