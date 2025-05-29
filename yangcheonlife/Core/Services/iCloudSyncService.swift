// iCloudSyncService.swift - iCloud Key-Value Store 동기화 서비스
import Foundation
import Combine

class iCloudSyncService: ObservableObject {
    
    static let shared = iCloudSyncService()
    
    // MARK: - Properties
    private let keyValueStore = NSUbiquitousKeyValueStore.default
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Sync Keys
    struct SyncKeys {
        static let defaultGrade = "sync_defaultGrade"
        static let defaultClass = "sync_defaultClass"
        static let notificationsEnabled = "sync_notificationsEnabled"
        static let physicalEducationAlertEnabled = "sync_physicalEducationAlertEnabled"
        static let physicalEducationAlertTime = "sync_physicalEducationAlertTime"
        static let wifiSuggestionEnabled = "sync_wifiSuggestionEnabled"
        static let cellBackgroundColor = "sync_cellBackgroundColor"
        
        // 탐구과목 선택은 동적으로 처리 (기존 로직 유지)
        static func selectedSubjectKey(for className: String) -> String {
            return "sync_selected\(className)Subject"
        }
    }
    
    // MARK: - Initialization
    private init() {
        setupNotificationObserver()
    }
    
    // MARK: - Setup
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.handleiCloudChange(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 설정값을 iCloud에 동기화
    func syncToiCloud() {
        let userDefaults = UserDefaults.standard
        
        // 기본 설정값들 동기화
        keyValueStore.set(userDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade), forKey: SyncKeys.defaultGrade)
        keyValueStore.set(userDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass), forKey: SyncKeys.defaultClass)
        keyValueStore.set(userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled), forKey: SyncKeys.notificationsEnabled)
        keyValueStore.set(userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertEnabled), forKey: SyncKeys.physicalEducationAlertEnabled)
        keyValueStore.set(userDefaults.object(forKey: AppConstants.UserDefaultsKeys.wifiSuggestionEnabled) as? Bool ?? true, forKey: SyncKeys.wifiSuggestionEnabled)
        
        // 체육 알림 시간
        if let timeString = userDefaults.string(forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertTime) {
            keyValueStore.set(timeString, forKey: SyncKeys.physicalEducationAlertTime)
        }
        
        // 셀 배경색 (RGB 값으로 저장)
        if let colorData = userDefaults.data(forKey: AppConstants.UserDefaultsKeys.cellBackgroundColor) {
            keyValueStore.set(colorData, forKey: SyncKeys.cellBackgroundColor)
        }
        
        // 탐구과목 선택사항들 (기존 로직에 따라 동적으로 처리)
        syncAllSubjectSelections()
        
        // 동기화 실행
        keyValueStore.synchronize()
    }
    
    /// iCloud에서 로컬로 설정값 복원
    func syncFromiCloud() {
        let userDefaults = UserDefaults.standard
        
        // 기본 설정값들
        let grade = keyValueStore.longLong(forKey: SyncKeys.defaultGrade)
        if grade > 0 {
            userDefaults.set(Int(grade), forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        }
        
        let classNumber = keyValueStore.longLong(forKey: SyncKeys.defaultClass)
        if classNumber > 0 {
            userDefaults.set(Int(classNumber), forKey: AppConstants.UserDefaultsKeys.defaultClass)
        }
        
        // Bool 값들 (기본값 확인 필요)
        if keyValueStore.object(forKey: SyncKeys.notificationsEnabled) != nil {
            userDefaults.set(keyValueStore.bool(forKey: SyncKeys.notificationsEnabled), forKey: AppConstants.UserDefaultsKeys.notificationsEnabled)
        }
        
        if keyValueStore.object(forKey: SyncKeys.physicalEducationAlertEnabled) != nil {
            userDefaults.set(keyValueStore.bool(forKey: SyncKeys.physicalEducationAlertEnabled), forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertEnabled)
        }
        
        if keyValueStore.object(forKey: SyncKeys.wifiSuggestionEnabled) != nil {
            userDefaults.set(keyValueStore.bool(forKey: SyncKeys.wifiSuggestionEnabled), forKey: AppConstants.UserDefaultsKeys.wifiSuggestionEnabled)
        }
        
        // 체육 알림 시간
        if let timeString = keyValueStore.string(forKey: SyncKeys.physicalEducationAlertTime) {
            userDefaults.set(timeString, forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertTime)
        }
        
        // 셀 배경색
        if let colorData = keyValueStore.data(forKey: SyncKeys.cellBackgroundColor) {
            userDefaults.set(colorData, forKey: AppConstants.UserDefaultsKeys.cellBackgroundColor)
        }
        
        // 탐구과목 선택사항들 (기존 로직에 따라 동적으로 복원)
        restoreAllSubjectSelections()
        
        // UI 업데이트를 위한 알림
        NotificationCenter.default.post(name: NSNotification.Name("iCloudSyncCompleted"), object: nil)
    }
    
    /// 특정 설정값만 iCloud에 동기화
    func syncSetting<T>(localKey: String, syncKey: String, value: T) {
        keyValueStore.set(value, forKey: syncKey)
        keyValueStore.synchronize()
    }
    
    // MARK: - Private Methods
    
    /// iCloud 변경사항 처리
    private func handleiCloudChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }
        
        // 외부 변경사항만 처리 (다른 기기에서의 변경)
        if reason == NSUbiquitousKeyValueStoreServerChange ||
           reason == NSUbiquitousKeyValueStoreInitialSyncChange {
            
            if let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
                handleChangedKeys(changedKeys)
            }
        }
    }
    
    /// 변경된 키들 처리
    private func handleChangedKeys(_ changedKeys: [String]) {
        let userDefaults = UserDefaults.standard
        
        for key in changedKeys {
            switch key {
            case SyncKeys.defaultGrade:
                let grade = keyValueStore.longLong(forKey: key)
                if grade > 0 {
                    userDefaults.set(Int(grade), forKey: AppConstants.UserDefaultsKeys.defaultGrade)
                }
                
            case SyncKeys.defaultClass:
                let classNumber = keyValueStore.longLong(forKey: key)
                if classNumber > 0 {
                    userDefaults.set(Int(classNumber), forKey: AppConstants.UserDefaultsKeys.defaultClass)
                }
                
            case SyncKeys.notificationsEnabled:
                userDefaults.set(keyValueStore.bool(forKey: key), forKey: AppConstants.UserDefaultsKeys.notificationsEnabled)
                
            case SyncKeys.physicalEducationAlertEnabled:
                userDefaults.set(keyValueStore.bool(forKey: key), forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertEnabled)
                
            case SyncKeys.wifiSuggestionEnabled:
                userDefaults.set(keyValueStore.bool(forKey: key), forKey: AppConstants.UserDefaultsKeys.wifiSuggestionEnabled)
                
            case SyncKeys.physicalEducationAlertTime:
                if let timeString = keyValueStore.string(forKey: key) {
                    userDefaults.set(timeString, forKey: AppConstants.UserDefaultsKeys.physicalEducationAlertTime)
                }
                
            case SyncKeys.cellBackgroundColor:
                if let colorData = keyValueStore.data(forKey: key) {
                    userDefaults.set(colorData, forKey: AppConstants.UserDefaultsKeys.cellBackgroundColor)
                }
                
            default:
                // 동적 탐구과목 키 처리 (기존 로직)
                if key.hasPrefix("sync_selected") && key.hasSuffix("Subject") {
                    let localKey = String(key.dropFirst(5)) // "sync_" 제거
                    if let subject = keyValueStore.string(forKey: key) {
                        userDefaults.set(subject, forKey: localKey)
                    }
                }
                break
            }
        }
        
        // UI 업데이트 알림
        NotificationCenter.default.post(name: NSNotification.Name("iCloudSyncCompleted"), object: nil)
    }
    
    /// 탐구과목 선택사항 동기화
    private func syncSubjectSelection(localKey: String, syncKey: String) {
        let userDefaults = UserDefaults.standard
        let subject = userDefaults.string(forKey: localKey) ?? ""
        keyValueStore.set(subject, forKey: syncKey)
    }
    
    /// 탐구과목 선택사항 복원
    private func restoreSubjectSelection(localKey: String, syncKey: String) {
        let userDefaults = UserDefaults.standard
        if let subject = keyValueStore.string(forKey: syncKey) {
            userDefaults.set(subject, forKey: localKey)
        }
    }
    
    /// 모든 탐구과목 선택사항 동기화 (기존 로직)
    private func syncAllSubjectSelections() {
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let subjectKeys = allKeys.filter { $0.hasPrefix("selected") && $0.hasSuffix("Subject") }
        
        for localKey in subjectKeys {
            let subject = userDefaults.string(forKey: localKey) ?? ""
            let syncKey = "sync_\(localKey)"
            keyValueStore.set(subject, forKey: syncKey)
        }
    }
    
    /// 모든 탐구과목 선택사항 복원 (기존 로직)
    private func restoreAllSubjectSelections() {
        // iCloud에서 모든 sync_selected*Subject 키를 찾아서 복원
        let allSyncKeys = Array(keyValueStore.dictionaryRepresentation.keys)
        let subjectSyncKeys = allSyncKeys.filter { $0.hasPrefix("sync_selected") && $0.hasSuffix("Subject") }
        
        for syncKey in subjectSyncKeys {
            let localKey = String(syncKey.dropFirst(5)) // "sync_" 제거
            if let subject = keyValueStore.string(forKey: syncKey) {
                UserDefaults.standard.set(subject, forKey: localKey)
            }
        }
    }
}