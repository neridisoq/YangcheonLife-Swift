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
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Timer for periodic updates (1분 간격으로 변경)
    lazy var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    // MARK: - Initialization
    init() {
        setupInitialValues()
        loadCellBackgroundColor()
        setupColorChangeNotification()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
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
        // 이전 교시 정보 저장 (Apple 정책 준수: 교시 변화 감지용)
        let previousPeriod = TimeUtility.getCurrentPeriodNumber()
        
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
        
        // 아침자습 시간 확인 및 WiFi 추천
        if wifiService.isMorningStudyTime() {
            suggestedWiFiConnection = wifiService.getMorningStudyWiFiSuggestion()
            currentClassInfo = ScheduleItem(
                grade: actualGrade,
                classNumber: actualClass,
                weekday: weekdayIndex,
                weekdayString: TimeUtility.weekdayIndexToKorean(weekdayIndex),
                period: 0,
                classroom: "\(actualGrade)학년 \(actualClass)반",
                subject: "아침자습"
            )
            return
        }
        
        // 점심자습 시간 확인 및 WiFi 추천
        if wifiService.isLunchStudyTime() {
            suggestedWiFiConnection = wifiService.getLunchStudyWiFiSuggestion()
            currentClassInfo = ScheduleItem(
                grade: actualGrade,
                classNumber: actualClass,
                weekday: weekdayIndex,
                weekdayString: TimeUtility.weekdayIndexToKorean(weekdayIndex),
                period: 0,
                classroom: "\(actualGrade)학년 \(actualClass)반",
                subject: "점심시간"
            )
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
            
        case .breakTime(let period):
            // 쉬는시간의 다음 수업 정보 가져오기
            if let classInfo = scheduleData.getClassInfo(weekday: weekdayIndex, period: period) {
                currentClassInfo = classInfo
                suggestedWiFiConnection = wifiService.getSuggestedWiFiConnection(for: classInfo)
            } else {
                currentClassInfo = nil
                suggestedWiFiConnection = nil
            }
            
        case .lunchTime:
            // 점심시간의 다음 수업(5교시) 정보 가져오기
            if let classInfo = scheduleData.getClassInfo(weekday: weekdayIndex, period: 5) {
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
        
        // Apple 정책 준수: 교시 변화 감지시에만 Live Activity 업데이트
        let currentPeriod = TimeUtility.getCurrentPeriodNumber()
        if previousPeriod != currentPeriod {
            print("📚 [PeriodChange] Period changed from \(previousPeriod ?? -1) to \(currentPeriod ?? -1)")
            if #available(iOS 18.0, *) {
                DispatchQueue.main.async {
                    LiveActivityManager.shared.updateOnClassPeriodChange()
                }
            }
        }
    }
    
    /// 타이머 시작
    func startTimer() {
        // Timer는 이미 lazy로 초기화되므로 별도 시작 불필요
    }
    
    /// 셀 배경색 로드
    func loadCellBackgroundColor() {
        let loadedColor = Color.loadFromUserDefaults(
            key: AppConstants.UserDefaultsKeys.cellBackgroundColor,
            defaultColor: Color.yellow // 기본 색상 (투명도 없음)
        )
        cellBackgroundColor = loadedColor.opacity(0.3) // 표시할 때 투명도 적용
    }
    
    /// 셀 배경색 저장
    func saveCellBackgroundColor(_ color: Color) {
        // 원본 색상을 저장하고, 표시용으로는 투명도 적용
        color.saveToUserDefaults(key: AppConstants.UserDefaultsKeys.cellBackgroundColor)
        cellBackgroundColor = color.opacity(0.3)
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
        case .lunchTime:
            return period == 5 // 점심시간에는 5교시를 강조
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
    
    // MARK: - Private Methods
    
    /// 색상 변경 알림 설정
    private func setupColorChangeNotification() {
        NotificationCenter.default.publisher(for: NSNotification.Name("CellBackgroundColorChanged"))
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.loadCellBackgroundColor()
                }
            }
            .store(in: &cancellables)
    }
}