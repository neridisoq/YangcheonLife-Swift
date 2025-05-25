// SettingsTabViewModel.swift - 설정 탭 뷰모델
import SwiftUI
import Foundation
import WidgetKit

class SettingsTabViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var defaultGrade: Int = 1
    @Published var defaultClass: Int = 1
    @Published var notificationsEnabled: Bool = false
    @Published var physicalEducationAlertEnabled: Bool = false
    @Published var physicalEducationAlertTime: Date = Date()
    @Published var cellBackgroundColor: Color = .currentPeriodBackground
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// 모든 설정 로드
    func loadSettings() {
        defaultGrade = userDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        defaultClass = userDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
        notificationsEnabled = userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled)
        physicalEducationAlertEnabled = userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertEnabled)
        
        // 기본값 설정
        if defaultGrade == 0 { defaultGrade = 1 }
        if defaultClass == 0 { defaultClass = 1 }
        
        // 체육 알림 시간 로드
        loadPhysicalEducationAlertTime()
        
        // 셀 배경색 로드
        loadCellBackgroundColor()
    }
    
    /// 학년 저장
    func saveDefaultGrade(_ grade: Int) {
        defaultGrade = grade
        userDefaults.set(grade, forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        updateSharedUserDefaults()
    }
    
    /// 반 저장
    func saveDefaultClass(_ classNumber: Int) {
        defaultClass = classNumber
        userDefaults.set(classNumber, forKey: AppConstants.UserDefaultsKeys.defaultClass)
        updateSharedUserDefaults()
    }
    
    /// 알림 활성화 상태 저장
    func saveNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        userDefaults.set(enabled, forKey: AppConstants.UserDefaultsKeys.notificationsEnabled)
        updateSharedUserDefaults()
    }
    
    /// 체육 알림 활성화 상태 저장
    func savePhysicalEducationAlertEnabled(_ enabled: Bool) {
        physicalEducationAlertEnabled = enabled
        userDefaults.set(enabled, forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertEnabled)
        updateSharedUserDefaults()
    }
    
    /// 체육 알림 시간 저장
    func savePhysicalEducationAlertTime(_ time: Date) {
        physicalEducationAlertTime = time
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: time)
        
        userDefaults.set(timeString, forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertTime)
        updateSharedUserDefaults()
    }
    
    /// 셀 배경색 저장
    func saveCellBackgroundColor(_ color: Color) {
        cellBackgroundColor = color
        
        // 투명도 적용
        let adjustedColor = color.opacity(0.3)
        adjustedColor.saveToUserDefaults(key: AppConstants.UserDefaultsKeys.cellBackgroundColor)
        
        updateSharedUserDefaults()
    }
    
    /// 모든 설정 초기화
    func resetAllSettings() {
        // UserDefaults 초기화
        let keys = [
            AppConstants.UserDefaultsKeys.defaultGrade,
            AppConstants.UserDefaultsKeys.defaultClass,
            AppConstants.UserDefaultsKeys.notificationsEnabled,
            AppConstants.UserDefaultsKeys.physicalEducationAlertEnabled,
            AppConstants.UserDefaultsKeys.physicalEducationAlertTime,
            AppConstants.UserDefaultsKeys.cellBackgroundColor,
            AppConstants.UserDefaultsKeys.initialSetupCompleted
        ]
        
        keys.forEach { userDefaults.removeObject(forKey: $0) }
        
        // 탐구과목 선택 초기화
        resetSubjectSelections()
        
        // 설정 다시 로드
        loadSettings()
        updateSharedUserDefaults()
    }
    
    /// 앱 데이터 내보내기 (백업용)
    func exportAppData() -> [String: Any] {
        var exportData: [String: Any] = [:]
        
        exportData["defaultGrade"] = defaultGrade
        exportData["defaultClass"] = defaultClass
        exportData["notificationsEnabled"] = notificationsEnabled
        exportData["physicalEducationAlertEnabled"] = physicalEducationAlertEnabled
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        exportData["physicalEducationAlertTime"] = formatter.string(from: physicalEducationAlertTime)
        
        // 탐구과목 선택사항도 포함
        exportData["subjectSelections"] = getSubjectSelections()
        
        exportData["exportDate"] = Date().timeIntervalSince1970
        exportData["appVersion"] = AppConstants.App.version
        
        return exportData
    }
    
    /// 앱 데이터 가져오기 (복원용)
    func importAppData(_ data: [String: Any]) -> Bool {
        guard let version = data["appVersion"] as? String,
              version == AppConstants.App.version else {
            return false // 버전이 다른 경우 가져오기 실패
        }
        
        if let grade = data["defaultGrade"] as? Int {
            saveDefaultGrade(grade)
        }
        
        if let classNumber = data["defaultClass"] as? Int {
            saveDefaultClass(classNumber)
        }
        
        if let enabled = data["notificationsEnabled"] as? Bool {
            saveNotificationsEnabled(enabled)
        }
        
        if let enabled = data["physicalEducationAlertEnabled"] as? Bool {
            savePhysicalEducationAlertEnabled(enabled)
        }
        
        if let timeString = data["physicalEducationAlertTime"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            if let time = formatter.date(from: timeString) {
                savePhysicalEducationAlertTime(time)
            }
        }
        
        if let selections = data["subjectSelections"] as? [String: String] {
            importSubjectSelections(selections)
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    /// 체육 알림 시간 로드
    private func loadPhysicalEducationAlertTime() {
        let timeString = userDefaults.string(forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertTime) ?? "07:00"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeString) {
            physicalEducationAlertTime = time
        } else {
            // 기본값: 오전 7시
            let calendar = Calendar.current
            physicalEducationAlertTime = calendar.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        }
    }
    
    /// 셀 배경색 로드
    private func loadCellBackgroundColor() {
        cellBackgroundColor = Color.loadFromUserDefaults(
            key: AppConstants.UserDefaultsKeys.cellBackgroundColor,
            defaultColor: .currentPeriodBackground
        )
    }
    
    /// 위젯과 데이터 동기화
    private func updateSharedUserDefaults() {
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        
        // 위젯 타임라인 업데이트
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// 탐구과목 선택사항 초기화
    private func resetSubjectSelections() {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let subjectKeys = allKeys.filter { $0.hasPrefix("selected") && $0.hasSuffix("Subject") }
        
        subjectKeys.forEach { userDefaults.removeObject(forKey: $0) }
    }
    
    /// 탐구과목 선택사항 가져오기
    private func getSubjectSelections() -> [String: String] {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let subjectKeys = allKeys.filter { $0.hasPrefix("selected") && $0.hasSuffix("Subject") }
        
        var selections: [String: String] = [:]
        subjectKeys.forEach { key in
            if let value = userDefaults.string(forKey: key) {
                selections[key] = value
            }
        }
        
        return selections
    }
    
    /// 탐구과목 선택사항 가져오기 (복원용)
    private func importSubjectSelections(_ selections: [String: String]) {
        selections.forEach { key, value in
            userDefaults.set(value, forKey: key)
        }
    }
}