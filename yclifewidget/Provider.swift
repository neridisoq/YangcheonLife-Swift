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
        let finalGrade = grade > 0 ? grade : 1
        let finalClass = classNumber > 0 ? classNumber : 1
        
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        print("⏱️ 위젯 Timeline 요청됨: \(dateFormatter.string(from: Date()))")
        
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        print("📊 위젯에서 읽은 학년/반: \(grade)학년 \(classNumber)반")
        
        // 만약 공유 UserDefaults에서 값을 읽지 못하면 기본값 설정
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        print("📊 위젯에 사용될 학년/반: \(finalGrade)학년 \(finalClass)반")
        
        let currentDate = Date()
        var entries: [NextClassEntry] = []
        
        // 향후 15분 동안의 항목들 추가 (1분 간격)
        for minute in 0...14 {
            let futureDate = Calendar.current.date(byAdding: .minute, value: minute, to: currentDate)!
            
            // 각 타임라인 항목에 대해 시간 정보를 포함한 고유한 표시 정보 생성
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: futureDate)
            let timeString = String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
            
            // 기본 표시 모드 가져오기
            let baseDisplayMode = WidgetScheduleManager.shared.getDisplayInfo()
            
            // 표시 모드에 따라 다른 처리
            var displayMode = baseDisplayMode
            
            // 일부 모드에서는 시간 정보를 추가하여 시각적인 차이 생성
            if case .nextClass(let nextClass) = displayMode {
                // 다음 수업 시작까지 남은 시간을 다르게 표시
                let modifiedNextClass = ClassInfo(
                    subject: nextClass.subject,
                    teacher: "\(nextClass.teacher) (\(timeString))",  // 교사 정보에 시간 추가
                    periodIndex: nextClass.periodIndex,
                    startTime: nextClass.startTime,
                    endTime: nextClass.endTime
                )
                displayMode = .nextClass(modifiedNextClass)
            }
            
            entries.append(NextClassEntry(
                date: futureDate,
                displayMode: displayMode,
                grade: finalGrade,
                classNumber: finalClass
            ))
        }
        
        // 정확한 로그를 위해 첫 번째와 마지막 항목의 시간 출력
        print("⏰ 현재시간: \(dateFormatter.string(from: currentDate))")
        if let lastEntry = entries.last {
            print("⏰ 마지막 항목 시간: \(dateFormatter.string(from: lastEntry.date)) (약 15분 후)")
        }
        
        // 타임라인 정책 설정
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        
        print("✅ 위젯 Timeline 생성 완료: \(dateFormatter.string(from: Date())) - \(entries.count)개 항목 포함")
        completion(timeline)
    }
}
