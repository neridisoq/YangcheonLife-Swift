import Foundation

class SharedUserDefaults {
    static let shared = SharedUserDefaults()
    
    private let suiteName = "group.com.yourcompany.yangcheonlife" // App Group 이름으로 변경 필요
    let userDefaults: UserDefaults
    
    private init() {
        if let sharedDefaults = UserDefaults(suiteName: suiteName) {
            userDefaults = sharedDefaults
        } else {
            userDefaults = UserDefaults.standard
            print("⚠️ App Group UserDefaults 초기화 실패, 표준 UserDefaults 사용")
        }
    }
    
    // 기존 앱의 UserDefaults에서 위젯용 공유 UserDefaults로 데이터 복사
    func synchronizeFromStandardUserDefaults() {
        let standardDefaults = UserDefaults.standard
        
        // 학년/반 정보 동기화
        if let grade = standardDefaults.object(forKey: "defaultGrade") {
            userDefaults.set(grade, forKey: "defaultGrade")
        }
        
        if let classNumber = standardDefaults.object(forKey: "defaultClass") {
            userDefaults.set(classNumber, forKey: "defaultClass")
        }
        
        // 탐구 과목 선택 정보 동기화
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.starts(with: "selected") && key.contains("Subject") {
                if let value = defaults.string(forKey: key) {
                    userDefaults.set(value, forKey: key)
                }
            }
        }
        
        // 시간표 데이터 동기화
        if let data = standardDefaults.data(forKey: "schedule_data_store") {
            userDefaults.set(data, forKey: "schedule_data_store")
        }
        
        userDefaults.synchronize()
    }
}