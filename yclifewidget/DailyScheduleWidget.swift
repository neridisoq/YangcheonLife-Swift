import WidgetKit
import SwiftUI

struct DailyScheduleWidget: Widget {
    let kind: String = "DailyScheduleWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyScheduleProvider()) { entry in
            if #available(iOS 17.0, *) {
                DailyScheduleWidgetView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                DailyScheduleWidgetView(entry: entry)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
            }
        }
        .configurationDisplayName("오늘의 시간표")
        .description("오늘 하루의 전체 시간표를 확인합니다.")
        .supportedFamilies([.systemLarge]) // 제일 큰 위젯 사이즈 사용
    }
}

struct DailyScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyScheduleEntry {
        return DailyScheduleEntry(
            date: Date(),
            schedule: [],
            grade: 3,
            classNumber: 5,
            currentPeriodIndex: -1,
            isNextDay: false
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DailyScheduleEntry) -> Void) {
        let sampleSchedule = [
            ScheduleItem(grade: 3, class: 5, weekday: 0, weekdayString: "월", classTime: 1, teacher: "301", subject: "수학"),
            ScheduleItem(grade: 3, class: 5, weekday: 0, weekdayString: "월", classTime: 2, teacher: "302", subject: "영어"),
            ScheduleItem(grade: 3, class: 5, weekday: 0, weekdayString: "월", classTime: 3, teacher: "체육관", subject: "체육"),
            ScheduleItem(grade: 3, class: 5, weekday: 0, weekdayString: "월", classTime: 4, teacher: "301", subject: "국어"),
            ScheduleItem(grade: 3, class: 5, weekday: 0, weekdayString: "월", classTime: 5, teacher: "303", subject: "사회"),
            ScheduleItem(grade: 3, class: 5, weekday: 0, weekdayString: "월", classTime: 6, teacher: "304", subject: "과학"),
            ScheduleItem(grade: 3, class: 5, weekday: 0, weekdayString: "월", classTime: 7, teacher: "301", subject: "진로")
        ]
        
        let entry = DailyScheduleEntry(
            date: Date(),
            schedule: sampleSchedule,
            grade: 3,
            classNumber: 5,
            currentPeriodIndex: 2,
            isNextDay: false
        )
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyScheduleEntry>) -> Void) {
        let sharedDefaults = SharedUserDefaults.shared.userDefaults
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        let finalGrade = grade > 0 ? grade : 3
        let finalClass = classNumber > 0 ? classNumber : 5
        
        let currentDate = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        let weekday = calendar.component(.weekday, from: currentDate)
        
        // 18시 이후에는 다음 날 시간표 표시
        let useNextDay = hour >= 18
        let targetDate = useNextDay ? calendar.date(byAdding: .day, value: 1, to: currentDate)! : currentDate
        let targetWeekday = useNextDay ?
            (weekday == 7 ? 2 : weekday + 1) : // 토요일(7)이면 다음 날은 월요일(2)
            weekday
        
        let apiWeekday = targetWeekday - 2 // 월요일: 0, 화요일: 1, ... 금요일: 4
        
        // Weekend check (현재가 주말이고 다음 날 표시가 아닌 경우 또는 금요일 18시 이후)
        if ((weekday == 1 || weekday == 7) && !useNextDay) ||
           (weekday == 6 && useNextDay) { // 금요일 18시 이후 = 다음 날은 토요일
            // Weekend - create an entry with empty schedule
            let entry = DailyScheduleEntry(
                date: currentDate,
                schedule: [],
                grade: finalGrade,
                classNumber: finalClass,
                currentPeriodIndex: -1,
                isNextDay: useNextDay
            )
            
            // 주말에는 다음 00시 01분에 갱신 (다음 날로 넘어갈 때)
            var nextMidnight = calendar.startOfDay(for: currentDate)
            nextMidnight = calendar.date(byAdding: .day, value: 1, to: nextMidnight)!
            nextMidnight = calendar.date(byAdding: .minute, value: 1, to: nextMidnight)! // 00:01에 갱신
            
            let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
            completion(timeline)
            return
        }
        
        // 다음 갱신 시간을 정확한 시간 간격(1분, 11분, 21분...)으로 설정
        let minute = calendar.component(.minute, from: currentDate)
        let minutesToAdd: Int
        
        // 1분, 11분, 21분, 31분, 41분, 51분에 갱신하도록 설정
        if minute < 1 {
            minutesToAdd = 1 - minute
        } else if minute < 11 {
            minutesToAdd = 11 - minute
        } else if minute < 21 {
            minutesToAdd = 21 - minute
        } else if minute < 31 {
            minutesToAdd = 31 - minute
        } else if minute < 41 {
            minutesToAdd = 41 - minute
        } else if minute < 51 {
            minutesToAdd = 51 - minute
        } else {
            // 다음 시간 1분에 갱신
            minutesToAdd = 61 - minute
        }
        
        let nextRefreshDate = calendar.date(byAdding: .minute, value: minutesToAdd, to: currentDate)!
        print("📆 다음 시간표 위젯 갱신 예정: \(formatTime(nextRefreshDate))")
        
        // Get schedule data from UserDefaults
        if let data = sharedDefaults.data(forKey: "schedule_data_store"),
           let scheduleData = try? JSONDecoder().decode(ScheduleData.self, from: data),
           apiWeekday >= 0 && apiWeekday < scheduleData.schedules.count {
            
            // Get the appropriate day's schedule
            let daySchedule = scheduleData.schedules[apiWeekday]
            
            // Get current period index (다음 날 시간표의 경우 현재 교시는 표시하지 않음)
            let currentPeriodIndex = useNextDay ? -1 : getCurrentPeriodIndex(now: currentDate)
            
            // 여러 타임라인 항목 생성
            var entries: [DailyScheduleEntry] = []
            
            // 현재 항목 추가
            entries.append(DailyScheduleEntry(
                date: currentDate,
                schedule: daySchedule,
                grade: finalGrade,
                classNumber: finalClass,
                currentPeriodIndex: currentPeriodIndex,
                isNextDay: useNextDay
            ))
            
            // 갱신 시간에 맞춰 정확한 타임라인 생성
            let timeline = Timeline(entries: entries, policy: .after(nextRefreshDate))
            completion(timeline)
        } else {
            // No schedule data available
            let entry = DailyScheduleEntry(
                date: currentDate,
                schedule: [],
                grade: finalGrade,
                classNumber: finalClass,
                currentPeriodIndex: -1,
                isNextDay: useNextDay
            )
            
            let timeline = Timeline(entries: [entry], policy: .after(nextRefreshDate))
            completion(timeline)
        }
    }
    
    // 시간 형식 출력 헬퍼 함수
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func getCurrentPeriodIndex(now: Date) -> Int {
        let periodTimes: [(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)] = [
            (8, 20, 9, 10), (9, 20, 10, 10), (10, 20, 11, 10), (11, 20, 12, 10),
            (13, 10, 14, 0), (14, 10, 15, 0), (15, 10, 16, 0)
        ]
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentTotalMinutes = hour * 60 + minute
        
        // 오전 7시 이전에는 아무 교시도 하이라이트하지 않음
        if hour < 7 {
            return -1
        }
        
        // If before first class starts but after 7 AM, highlight first period
        if currentTotalMinutes < periodTimes[0].startHour * 60 + periodTimes[0].startMinute {
            return 0 // First class is next
        }
        
        // If after last class ends
        if currentTotalMinutes > periodTimes.last!.endHour * 60 + periodTimes.last!.endMinute {
            return -1 // No class is next
        }
        
        // Check if within a class period
        for (index, period) in periodTimes.enumerated() {
            let startTotalMinutes = period.startHour * 60 + period.startMinute
            let endTotalMinutes = period.endHour * 60 + period.endMinute
            
            // Within class period
            if currentTotalMinutes >= startTotalMinutes && currentTotalMinutes <= endTotalMinutes {
                return index
            }
            
            // During break time, check if the next class is coming
            if index < periodTimes.count - 1 {
                let nextStartTotalMinutes = periodTimes[index + 1].startHour * 60 + periodTimes[index + 1].startMinute
                
                // Modified to highlight the next class during break time
                if currentTotalMinutes > endTotalMinutes && currentTotalMinutes < nextStartTotalMinutes {
                    return index + 1 // Return the next class index
                }
            }
        }
        
        return -1 // Default, no class is next
    }
}

struct DailyScheduleEntry: TimelineEntry {
    let date: Date
    let schedule: [ScheduleItem]
    let grade: Int
    let classNumber: Int
    let currentPeriodIndex: Int
    let isNextDay: Bool
    
    init(date: Date, schedule: [ScheduleItem], grade: Int, classNumber: Int, currentPeriodIndex: Int, isNextDay: Bool = false) {
        self.date = date
        self.schedule = schedule
        self.grade = grade
        self.classNumber = classNumber
        self.currentPeriodIndex = currentPeriodIndex
        self.isNextDay = isNextDay
    }
}

struct DailyScheduleWidgetView: View {
    var entry: DailyScheduleEntry
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
            
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack {
                    let dateString = formatDate(entry.isNextDay ?
                                               Calendar.current.date(byAdding: .day, value: 1, to: entry.date)! :
                                               entry.date)
                    Text("\(dateString) 시간표\(entry.isNextDay ? " (내일)" : "")")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("\(entry.grade)학년 \(entry.classNumber)반")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 2)
                
                if !entry.schedule.isEmpty {
                    // Schedule list - Using VStack instead of ScrollView to avoid warning
                    VStack(spacing: 4) {
                        ForEach(0..<7) { index in
                            let scheduleItem = entry.schedule.first { $0.classTime == index + 1 }
                            
                            ScheduleItemView(
                                scheduleItem: scheduleItem,
                                periodIndex: index,
                                isCurrentPeriod: index == entry.currentPeriodIndex
                            )
                        }
                    }
                } else {
                    Spacer()
                    Text("오늘은 수업이 없습니다")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
            }
            .padding()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

struct ScheduleItemView: View {
    var scheduleItem: ScheduleItem?
    var periodIndex: Int
    var isCurrentPeriod: Bool
    
    var body: some View {
        HStack {
            // Period number
            Text("\(periodIndex + 1)")
                .font(.system(size: 16, weight: .bold))
                .frame(width: 24, height: 24)
                .background(isCurrentPeriod ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            
            // Schedule item details
            if let item = scheduleItem {
                let displaySubject = getDisplaySubject(scheduleItem: item)
                let displayLocation = getDisplayLocation(scheduleItem: item)
                
                HStack {
                    Text(displaySubject)
                        .font(.system(size: 15, weight: isCurrentPeriod ? .bold : .regular))
                        .foregroundColor(isCurrentPeriod ? .blue : .primary)
                    
                    Spacer()
                    
                    Text(displayLocation)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(isCurrentPeriod ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(8)
                .frame(maxWidth: .infinity)
            } else {
                Text("수업 없음")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private func getDisplaySubject(scheduleItem: ScheduleItem) -> String {
        var displaySubject = scheduleItem.subject
        
        if scheduleItem.subject.contains("반") {
            let customKey = "selected\(scheduleItem.subject)Subject"
            
            if let selectedSubject = UserDefaults.standard.string(forKey: customKey),
               selectedSubject != "선택 없음" && selectedSubject != scheduleItem.subject {
                
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    displaySubject = components[0]
                }
            }
        }
        
        return displaySubject
    }
    
    private func getDisplayLocation(scheduleItem: ScheduleItem) -> String {
        var displayLocation = scheduleItem.teacher
        
        if scheduleItem.subject.contains("반") {
            let customKey = "selected\(scheduleItem.subject)Subject"
            
            if let selectedSubject = UserDefaults.standard.string(forKey: customKey),
               selectedSubject != "선택 없음" && selectedSubject != scheduleItem.subject {
                
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    displayLocation = components[1]
                }
            }
        }
        
        return displayLocation
    }
}
