import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NextClassEntry {
        print("🔄 위젯 Placeholder 요청됨")
        return NextClassEntry(
            date: Date(),
            displayMode: .noInfo,
            grade: 3,
            classNumber: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextClassEntry) -> ()) {
        print("📸 위젯 Snapshot 요청됨")
        
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        print("📊 위젯에서 읽은 학년/반: \(grade)학년 \(classNumber)반")
        
        // UserDefaults 내용 로깅
        SharedUserDefaults.shared.printAllValues()
        
        // 만약 공유 UserDefaults에서 값을 읽지 못하면 기본값 설정
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        print("📊 위젯에 사용될 학년/반: \(finalGrade)학년 \(finalClass)반")
        
        let displayMode = WidgetScheduleManager.shared.getDisplayInfo()
        
        let entry = NextClassEntry(
            date: Date(),
            displayMode: displayMode,
            grade: finalGrade,
            classNumber: finalClass
        )
        
        print("✅ 위젯 Snapshot 생성 완료")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextClassEntry>) -> ()) {
        print("⏱️ 위젯 Timeline 요청됨")
        
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        print("📊 위젯에서 읽은 학년/반: \(grade)학년 \(classNumber)반")
        
        // 만약 공유 UserDefaults에서 값을 읽지 못하면 기본값 설정
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        print("📊 위젯에 사용될 학년/반: \(finalGrade)학년 \(finalClass)반")
        
        let displayMode = WidgetScheduleManager.shared.getDisplayInfo()
        
        let currentDate = Date()
        let entry = NextClassEntry(
            date: currentDate,
            displayMode: displayMode,
            grade: finalGrade,
            classNumber: finalClass
        )
        
        // 다음 업데이트 시간을 1분 후로 설정
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate) ?? currentDate
        print("⏰ 다음 업데이트: \(nextUpdateDate) (1분 후)")
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        print("✅ 위젯 Timeline 생성 완료")
        completion(timeline)
    }
}
