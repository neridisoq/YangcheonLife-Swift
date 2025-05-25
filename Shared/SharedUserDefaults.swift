import Foundation

public class SharedUserDefaults {
    public static let shared = SharedUserDefaults()
    
    // App Group 이름
    private let suiteName = "group.com.helgisnw.yangcheonlife"
    public let userDefaults: UserDefaults
    
    private init() {
        if let sharedDefaults = UserDefaults(suiteName: suiteName) {
            userDefaults = sharedDefaults
            print("✅ App Group UserDefaults 초기화 성공: \(suiteName)")
            
            // iOS 15 디버깅용 추가 정보
            let grade = sharedDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
            let classNumber = sharedDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
            print("📊 공유 UserDefaults 초기 값: 학년=\(grade), 반=\(classNumber)")
            
            if grade == 0 || classNumber == 0 {
                print("⚠️ 공유 UserDefaults에 기본 값이 없음. 표준 UserDefaults에서 확인 시도...")
                let standardGrade = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
                let standardClass = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
                print("📊 표준 UserDefaults 값: 학년=\(standardGrade), 반=\(standardClass)")
            }
        } else {
            userDefaults = UserDefaults.standard
            print("⚠️ App Group UserDefaults 초기화 실패, 표준 UserDefaults 사용")
            print("⚠️ 시도한 suiteName: \(suiteName)")
        }
    }
    
    // 기존 앱의 UserDefaults에서 위젯용 공유 UserDefaults로 데이터 복사
    // 기존 앱의 UserDefaults에서 위젯용 공유 UserDefaults로 데이터 복사
    public func synchronizeFromStandardUserDefaults() {
        let standardDefaults = UserDefaults.standard
        
        // 학년/반 정보 동기화
        let grade = standardDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        let classNumber = standardDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
        
        userDefaults.set(grade, forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        userDefaults.set(classNumber, forKey: AppConstants.UserDefaultsKeys.defaultClass)
        
        print("📱 App → Widget 데이터 동기화: 학년=\(grade), 반=\(classNumber)")
        
        // 탐구 과목 선택 정보 동기화
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        var subjectCount = 0
        
        for key in allKeys {
            if key.starts(with: "selected") && key.contains("Subject") {
                if let value = defaults.string(forKey: key) {
                    userDefaults.set(value, forKey: key)
                    subjectCount += 1
                }
            }
        }
        
        print("📚 탐구 과목 \(subjectCount)개 동기화 완료")
        
        // 시간표 데이터 동기화
        if let data = standardDefaults.data(forKey: AppConstants.UserDefaultsKeys.scheduleDataStore) {
            userDefaults.set(data, forKey: AppConstants.UserDefaultsKeys.scheduleDataStore)
            print("📅 시간표 데이터 동기화 완료: \(data.count) 바이트")
            
            // 시간표 데이터 확인 (새로운 모델 타입 사용)
            do {
                let scheduleData = try JSONDecoder().decode(ScheduleData.self, from: data)
                print("✓ 시간표 데이터 확인: \(scheduleData.grade)학년 \(scheduleData.classNumber)반")
            } catch {
                print("⚠️ 시간표 데이터 파싱 확인 실패: \(error)")
            }
        } else {
            print("⚠️ 시간표 데이터 없음")
        }
        
        userDefaults.synchronize()
        
        // 동기화 후 확인
        let syncedGrade = userDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        let syncedClass = userDefaults.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
        print("🔄 동기화 완료 확인: 학년=\(syncedGrade), 반=\(syncedClass)")
    }
    // 디버깅용: 공유 UserDefaults의 모든 내용 출력
    public func printAllValues() {
        print("📋 공유 UserDefaults 내용:")
        for (key, value) in userDefaults.dictionaryRepresentation() {
            print("   \(key): \(value)")
        }
    }
    
}
