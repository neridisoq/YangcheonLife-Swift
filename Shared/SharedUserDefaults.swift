import Foundation

public class SharedUserDefaults {
    public static let shared = SharedUserDefaults()
    
    // App Group 이름
    private let suiteName = "group.com.helgisnw.yangcheonlife"
    public let userDefaults: UserDefaults
    
    private init() {
        if let sharedDefaults = UserDefaults(suiteName: suiteName) {
            userDefaults = sharedDefaults
            print("✅ App Group UserDefaults 초기화 성공: \(userDefaults)")
        } else {
            userDefaults = UserDefaults.standard
            print("⚠️ App Group UserDefaults 초기화 실패, 표준 UserDefaults 사용")
        }
    }
    
    // 기존 앱의 UserDefaults에서 위젯용 공유 UserDefaults로 데이터 복사
    // 기존 앱의 UserDefaults에서 위젯용 공유 UserDefaults로 데이터 복사
    public func synchronizeFromStandardUserDefaults() {
        let standardDefaults = UserDefaults.standard
        
        // 학년/반 정보 동기화
        let grade = standardDefaults.integer(forKey: "defaultGrade")
        let classNumber = standardDefaults.integer(forKey: "defaultClass")
        
        userDefaults.set(grade, forKey: "defaultGrade")
        userDefaults.set(classNumber, forKey: "defaultClass")
        
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
        if let data = standardDefaults.data(forKey: "schedule_data_store") {
            userDefaults.set(data, forKey: "schedule_data_store")
            print("📅 시간표 데이터 동기화 완료: \(data.count) 바이트")
            
            // 시간표 데이터 확인
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
        let syncedGrade = userDefaults.integer(forKey: "defaultGrade")
        let syncedClass = userDefaults.integer(forKey: "defaultClass")
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
