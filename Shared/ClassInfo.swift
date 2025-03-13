import Foundation
import WidgetKit

// 위젯에 표시할 수업 정보 구조체
public struct ClassInfo {
    public let subject: String
    public let teacher: String  // 교실
    public let periodIndex: Int
    public let startTime: Date
    public let endTime: Date
    
    public init(subject: String, teacher: String, periodIndex: Int, startTime: Date, endTime: Date) {
        self.subject = subject
        self.teacher = teacher
        self.periodIndex = periodIndex
        self.startTime = startTime
        self.endTime = endTime
    }
}

// 디스플레이 모드 열거형
public enum DisplayMode {
    case nextClass(ClassInfo)
    case peInfo(weekday: Int, hasPhysicalEducation: Bool)
    case mealInfo(MealInfo)  // 추가
    case noInfo
}

// 위젯 엔트리 구조체
public struct NextClassEntry: TimelineEntry {
    public let date: Date
    public let displayMode: DisplayMode
    public let grade: Int
    public let classNumber: Int
    
    public init(date: Date, displayMode: DisplayMode, grade: Int, classNumber: Int) {
        self.date = date
        self.displayMode = displayMode
        self.grade = grade
        self.classNumber = classNumber
    }
}

public class WidgetScheduleManager {
    public static let shared = WidgetScheduleManager()
    
    private let sharedDefaults = SharedUserDefaults.shared.userDefaults
    
    private init() {}
    
    // 요일별 일과 종료 시간 확인
    private func getLastPeriodEndTime(weekday: Int) -> Int {
        // 수요일(4)과 금요일(6)은 15:00, 그 외에는 16:00
        return (weekday == 4 || weekday == 6) ? 15 * 60 : 16 * 60
    }
    
    // 급식 정보 표시가 필요한지 확인
    // 급식 정보 표시가 필요한지 확인
    // 수정된 코드:
    private func shouldShowMealInfo(now: Date) -> (shouldShow: Bool, mealType: MealType?) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentTotalMinutes = hour * 60 + minute
        
        // 주말은 급식 정보 표시 안함
        let weekday = calendar.component(.weekday, from: now)
        if weekday == 1 || weekday == 7 {
            return (false, nil)
        }
        
        // 중식 표시 시간: 11:20부터 12:40까지로 변경
        let lunchStartTime = 11 * 60 + 20
        let lunchEndTime = 12 * 60 + 40  // 13:00에서 12:40으로 변경
        
        if currentTotalMinutes >= lunchStartTime && currentTotalMinutes < lunchEndTime {
            return (true, .lunch)
        }
        
        return (false, nil)
    }
    
    // 시간표 데이터 로드
    private func loadScheduleData(grade: Int, classNumber: Int) -> ScheduleData? {
        print("📂 시간표 데이터 로드 시도: \(grade)학년 \(classNumber)반")
        
        guard let data = sharedDefaults.data(forKey: "schedule_data_store") else {
            print("⚠️ 시간표 데이터 없음")
            return nil
        }
        
        print("📦 시간표 데이터 크기: \(data.count) 바이트")
        
        do {
            let scheduleData = try JSONDecoder().decode(ScheduleData.self, from: data)
            print("✅ 시간표 데이터 파싱 성공: \(scheduleData.grade)학년 \(scheduleData.classNumber)반, \(scheduleData.schedules.count)일 시간표")
            
            return scheduleData
        } catch {
            print("❌ 시간표 데이터 파싱 실패: \(error)")
            return nil
        }
    }
    
    // 다음 수업 또는 체육 정보 가져오기
    public func getDisplayInfo() -> DisplayMode {
        print("🔍 위젯 표시 정보 요청")
        
        // 유저 기본 설정 확인
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        // 현재 시간 확인
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentTotalMinutes = hour * 60 + minute
        
        // 요일별 일과 종료 시간
        let lastPeriodEnd = getLastPeriodEndTime(weekday: weekday)
        
        // 아침 표시 시간 기준 (7:30)
        let morningDisplayTime = 7 * 60 + 30
        
        print("⏰ 현재 시간: \(hour):\(minute) (\(currentTotalMinutes)분)")
        
        // 급식 정보 표시가 필요한지 확인
        let mealInfo = shouldShowMealInfo(now: now)
        if mealInfo.shouldShow, let mealType = mealInfo.mealType {
            // 캐시된 급식 정보 확인
            if let cachedMeal = NeisAPIManager.shared.getCachedMeal(date: now, mealType: mealType) {
                print("🍱 캐시된 \(mealType.name) 정보 사용")
                return .mealInfo(cachedMeal)
            }
            
            // 동기식으로 처리하기 위한 세마포어
            let semaphore = DispatchSemaphore(value: 0)
            var fetchedMealInfo: MealInfo? = nil
            
            // 급식 정보 가져오기
            NeisAPIManager.shared.fetchMeal(date: now, mealType: mealType) { mealInfo in
                fetchedMealInfo = mealInfo
                semaphore.signal()
            }
            
            // 최대 1초까지만 대기
            _ = semaphore.wait(timeout: .now() + 1.0)
            
            if let mealInfo = fetchedMealInfo {
                print("🍱 \(mealType.name) 정보 찾음")
                // 캐시에 저장
                NeisAPIManager.shared.cacheMeal(date: now, mealInfo: mealInfo)
                return .mealInfo(mealInfo)
            }
        }
        
        // 일과 종료 이후 또는 아침 7:30 이전 -> 체육 정보
        if currentTotalMinutes >= lastPeriodEnd || currentTotalMinutes < morningDisplayTime {
            print("🕒 일과 종료 후 또는 아침 7:30 이전: 체육 정보 확인")
            if let peInfo = getNextDayPEInfo() {
                print("🏃‍♂️ 체육 정보 찾음: \(peInfo.weekday)요일, 체육\(peInfo.hasPhysicalEducation ? "있음" : "없음")")
                return .peInfo(weekday: peInfo.weekday, hasPhysicalEducation: peInfo.hasPhysicalEducation)
            }
        } else {
            // 오전 7:30부터 일과 종료까지는 다음 수업 정보 표시
            print("📚 수업 시간대: 다음 수업 정보 확인")
            if let nextClass = getNextClass() {
                print("✅ 다음 수업 찾음: \(nextClass.subject) (\(nextClass.teacher))")
                return .nextClass(nextClass)
            }
        }
        
        // 정보 없음
        print("❌ 표시할 정보 없음")
        return .noInfo
    }

    // 다음 날 체육 정보 확인 함수
    private func getNextDayPEInfo() -> (weekday: Int, hasPhysicalEducation: Bool)? {
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        guard let scheduleData = loadScheduleData(grade: grade, classNumber: classNumber) else {
            return nil
        }
        
        // 현재 요일 확인
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now) // 일요일: 1, 월요일: 2, ...
        
        print("📆 체육 정보 확인 - 현재 요일: \(currentWeekday) (\(getWeekdayString(currentWeekday)))")
        
        // 오늘이 주중인 경우 당일 체육 수업 확인
        let apiWeekday = currentWeekday - 2 // 월요일: 0, 화요일: 1, ...
        let checkToday = currentWeekday >= 2 && currentWeekday <= 6
        
        if checkToday && apiWeekday >= 0 && apiWeekday < scheduleData.schedules.count {
            let todaySchedule = scheduleData.schedules[apiWeekday]
            let hasPEToday = todaySchedule.contains { item in
                return item.subject.contains("체육") || item.subject.contains("운건")
            }
            
            // 오전 7:30 이전에는 오늘의 체육 수업 정보 표시
            let hour = calendar.component(.hour, from: now)
            let minute = calendar.component(.minute, from: now)
            let currentTotalMinutes = hour * 60 + minute
            let morningDisplayTime = 7 * 60 + 30
            
            if currentTotalMinutes < morningDisplayTime {
                print("🏃‍♂️ 오늘(\(currentWeekday)요일) 체육 수업 \(hasPEToday ? "있음" : "없음")")
                return (currentWeekday, hasPEToday)
            }
        }
        
        // 다음 요일 계산 (금요일(6)이면 다음 주 월요일(2), 그외에는 다음 평일)
        var nextWeekday = currentWeekday + 1
        if nextWeekday > 6 || currentWeekday == 6 { // 금요일(6) 또는 토요일(7)이면 월요일(2)
            nextWeekday = 2
        }
        
        print("📆 체육 정보 확인 - 다음 요일: \(nextWeekday) (\(getWeekdayString(nextWeekday)))")
        
        // 시스템 요일을 API 요일 인덱스로 변환
        let nextApiWeekday = nextWeekday - 2 // 월요일: 0, 화요일: 1, ...
        
        print("📆 체육 정보 확인 - 다음 API 요일 인덱스: \(nextApiWeekday)")
        
        // 다음 날 시간표에서 체육 수업 찾기
        if nextApiWeekday >= 0 && nextApiWeekday < scheduleData.schedules.count {
            let daySchedule = scheduleData.schedules[nextApiWeekday]
            
            let hasPhysicalEducation = daySchedule.contains { item in
                let isPE = item.subject.contains("체육") || item.subject.contains("운건")
                if isPE {
                    print("🏃‍♂️ 체육 수업 발견: \(nextWeekday)요일 (\(getWeekdayString(nextWeekday))) - \(item.subject)")
                }
                return isPE
            }
            
            print("🏃‍♂️ \(nextWeekday)요일 (\(getWeekdayString(nextWeekday))) 체육 수업 \(hasPhysicalEducation ? "있음" : "없음")")
            return (nextWeekday, hasPhysicalEducation)
        }
        
        return nil
    }
    
    // 요일 숫자를 문자열로 변환하는 도우미 함수
    private func getWeekdayString(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "일요일"
        case 2: return "월요일"
        case 3: return "화요일"
        case 4: return "수요일"
        case 5: return "목요일"
        case 6: return "금요일"
        case 7: return "토요일"
        default: return "알 수 없음"
        }
    }
    
    // 다음 수업 정보 가져오기
    public func getNextClass() -> ClassInfo? {
        // 현재 요일 및 시간 확인
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now) // 일요일: 1, 월요일: 2, ...
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        print("⏰ 현재 시간: 요일=\(weekday) \(hour):\(minute)")
        
        // 주말이면 다음 월요일 첫 수업 반환
        if weekday == 1 || weekday == 7 {
            print("🏖️ 주말 감지: 다음 월요일 첫 수업 찾는 중")
            return getNextMondayFirstClass()
        }
        
        // 현재 학년/반 가져오기
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        print("👨‍🎓 설정된 학년/반: \(grade)학년 \(classNumber)반")
        
        // 시간표 데이터 가져오기
        guard let scheduleData = loadScheduleData(grade: grade, classNumber: classNumber) else {
            print("⚠️ 시간표 데이터 로드 실패")
            return nil
        }
        
        // 제공된 JSON 형식에서는 월요일이 0, 화요일이 1, ...이므로 조정
        // 시스템의 weekday는 일요일이 1, 월요일이 2, ...이므로 2를 빼서 조정
        let apiWeekday = weekday - 2
        
        print("📊 API 요일 인덱스: \(apiWeekday) (요일: \(weekday))")
        
        // 유효한 요일 확인
        guard apiWeekday >= 0 && apiWeekday < scheduleData.schedules.count else {
            print("⚠️ 유효하지 않은 요일 인덱스: \(apiWeekday)")
            return nil
        }
        
        // 해당 요일의 시간표 가져오기
        let daySchedule = scheduleData.schedules[apiWeekday]
        print("📚 오늘 수업 수: \(daySchedule.count)개")
        
        // 개발/테스트 목적으로 첫 번째 수업 정보 출력
        if let firstClass = daySchedule.first {
            print("🔍 첫 번째 수업: \(firstClass.subject) (\(firstClass.teacher))")
        }
        
        // 1교시 시간 확인 - 8:20~9:10
        let firstPeriodStart = 8 * 60 + 20
        let firstPeriodEnd = 9 * 60 + 10
        let currentTotalMinutes = hour * 60 + minute
        
        // 1교시 시작 전이면 1교시 수업 표시
        if currentTotalMinutes < firstPeriodStart {
            if !daySchedule.isEmpty {
                let firstPeriodClass = daySchedule[0]
                print("✅ 1교시 수업: \(firstPeriodClass.subject)")
                
                if let classTime = createClassTime(periodIndex: 0) {
                    return ClassInfo(
                        subject: getDisplaySubject(scheduleItem: firstPeriodClass),
                        teacher: getDisplayLocation(scheduleItem: firstPeriodClass),
                        periodIndex: 0,
                        startTime: classTime.startTime,
                        endTime: classTime.endTime
                    )
                }
            }
        }
        
        // 1교시 시간대에는 2교시 수업 표시
        if currentTotalMinutes >= firstPeriodStart && currentTotalMinutes <= firstPeriodEnd {
            print("🔍 1교시 감지: 2교시 수업 표시")
            
            // 2교시 수업 정보 가져오기 (인덱스는 1)
            if daySchedule.count > 1 {
                let secondPeriodClass = daySchedule[1]
                print("✅ 2교시 수업: \(secondPeriodClass.subject)")
                
                if let classTime = createClassTime(periodIndex: 1) {
                    return ClassInfo(
                        subject: getDisplaySubject(scheduleItem: secondPeriodClass),
                        teacher: getDisplayLocation(scheduleItem: secondPeriodClass),
                        periodIndex: 1,
                        startTime: classTime.startTime,
                        endTime: classTime.endTime
                    )
                }
            }
        }
        
        // 현재 수업 인덱스 찾기
        let currentPeriodIndex = getCurrentPeriodIndex(now: now)
        print("🔍 현재 수업 인덱스: \(currentPeriodIndex)")
        
        // 다음 수업 찾기
        for i in 0..<daySchedule.count {
            // 현재 교시보다 이후의 수업 중 첫 번째로 찾은 수업 반환
            if i > currentPeriodIndex {
                let classItem = daySchedule[i]
                
                // classTime은 1부터 시작하므로 인덱스는 classTime - 1
                if let classTime = createClassTime(periodIndex: classItem.classTime - 1) {
                    print("✅ 다음 수업 찾음: \(classItem.classTime)교시 \(classItem.subject)")
                    return ClassInfo(
                        subject: getDisplaySubject(scheduleItem: classItem),
                        teacher: getDisplayLocation(scheduleItem: classItem),
                        periodIndex: classItem.classTime - 1,
                        startTime: classTime.startTime,
                        endTime: classTime.endTime
                    )
                }
            }
        }
        
        print("🔍 오늘 남은 수업 없음, 다음 요일 첫 수업 찾는 중")
        // 오늘 남은 수업이 없으면 다음 요일 첫 수업 찾기
        return getNextDayFirstClass(currentWeekday: weekday)
    }
    
    private func getNextDayFirstClass(currentWeekday: Int) -> ClassInfo? {
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        guard let scheduleData = loadScheduleData(grade: grade, classNumber: classNumber) else {
            return nil
        }
        
        // 다음 요일 확인 (월요일~금요일 순환)
        var nextWeekday = currentWeekday + 1
        if nextWeekday > 6 {
            nextWeekday = 2 // 다음 주 월요일
        }
        
        // API에서는 월요일이 0, 화요일이 1, ... 금요일이 4로 인덱싱됨
        let apiWeekday = nextWeekday - 2
        
        // 다음 요일 시간표 확인
        if apiWeekday >= 0 && apiWeekday < scheduleData.schedules.count,
           !scheduleData.schedules[apiWeekday].isEmpty {
            // 첫 번째 수업 찾기
            let firstSchedule = scheduleData.schedules[apiWeekday][0]
            if !firstSchedule.subject.isEmpty {
                // 해당 요일의 첫 수업 정보 생성
                if let classTime = createClassTimeForDay(periodIndex: 0, daysToAdd: 1) {
                    return ClassInfo(
                        subject: getDisplaySubject(scheduleItem: firstSchedule),
                        teacher: getDisplayLocation(scheduleItem: firstSchedule),
                        periodIndex: 0,
                        startTime: classTime.startTime,
                        endTime: classTime.endTime
                    )
                }
            }
        }
        
        // 다음 날에 수업이 없으면 그 다음 날 확인 (최대 금요일까지)
        for offset in 2...5 {
            let checkWeekday = currentWeekday + offset
            if checkWeekday > 6 {
                break // 주말은 건너뜀
            }
            
            let checkApiWeekday = checkWeekday - 2
            if checkApiWeekday >= 0 && checkApiWeekday < scheduleData.schedules.count,
               !scheduleData.schedules[checkApiWeekday].isEmpty {
                let firstSchedule = scheduleData.schedules[checkApiWeekday][0]
                if !firstSchedule.subject.isEmpty {
                    if let classTime = createClassTimeForDay(periodIndex: 0, daysToAdd: offset) {
                        return ClassInfo(
                            subject: getDisplaySubject(scheduleItem: firstSchedule),
                            teacher: getDisplayLocation(scheduleItem: firstSchedule),
                            periodIndex: 0,
                            startTime: classTime.startTime,
                            endTime: classTime.endTime
                        )
                    }
                }
            }
        }
        
        // 이번 주에 수업이 없으면 다음 주 월요일 첫 수업
        return getNextMondayFirstClass()
    }
    
    private func getNextMondayFirstClass() -> ClassInfo? {
        let grade = sharedDefaults.integer(forKey: "defaultGrade")
        let classNumber = sharedDefaults.integer(forKey: "defaultClass")
        
        guard let scheduleData = loadScheduleData(grade: grade, classNumber: classNumber),
              !scheduleData.schedules[0].isEmpty else {
            return nil
        }
        
        // 월요일 첫 수업 찾기
        let firstSchedule = scheduleData.schedules[0][0]
        if !firstSchedule.subject.isEmpty {
            // 다음 주 월요일까지 날짜 계산
            let calendar = Calendar.current
            let now = Date()
            let weekday = calendar.component(.weekday, from: now)
            let daysUntilNextMonday = (9 - weekday) % 7 // 다음 월요일까지 남은 일수
            
            if let classTime = createClassTimeForDay(periodIndex: 0, daysToAdd: daysUntilNextMonday) {
                return ClassInfo(
                    subject: getDisplaySubject(scheduleItem: firstSchedule),
                    teacher: getDisplayLocation(scheduleItem: firstSchedule),
                    periodIndex: 0,
                    startTime: classTime.startTime,
                    endTime: classTime.endTime
                )
            }
        }
        
        return nil
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
        
        // 첫 수업 시작 전
        if currentTotalMinutes < periodTimes[0].startHour * 60 + periodTimes[0].startMinute {
            return -1
        }
        
        // 마지막 수업 종료 후
        if currentTotalMinutes > periodTimes.last!.endHour * 60 + periodTimes.last!.endMinute {
            return periodTimes.count
        }
        
        // 현재 진행 중인 교시 또는 쉬는 시간 찾기
        for (index, period) in periodTimes.enumerated() {
            let startTotalMinutes = period.startHour * 60 + period.startMinute
            let endTotalMinutes = period.endHour * 60 + period.endMinute
            
            // 현재 시간이 이 교시 시간 내에 있음
            if currentTotalMinutes >= startTotalMinutes && currentTotalMinutes <= endTotalMinutes {
                return index
            }
            
            // 쉬는 시간 (현재 교시와 다음 교시 사이)
            if index < periodTimes.count - 1 {
                let nextStartTotalMinutes = periodTimes[index + 1].startHour * 60 + periodTimes[index + 1].startMinute
                if currentTotalMinutes > endTotalMinutes && currentTotalMinutes < nextStartTotalMinutes {
                    return index
                }
            }
        }
        
        return periodTimes.count - 1 // 기본적으로 마지막 교시 반환
    }
    
    private func createClassTime(periodIndex: Int) -> (startTime: Date, endTime: Date)? {
        let periodTimes: [(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)] = [
            (8, 20, 9, 10), (9, 20, 10, 10), (10, 20, 11, 10), (11, 20, 12, 10),
            (13, 10, 14, 0), (14, 10, 15, 0), (15, 10, 16, 0)
        ]
        
        guard periodIndex >= 0 && periodIndex < periodTimes.count else {
            return nil
        }
        
        let period = periodTimes[periodIndex]
        let calendar = Calendar.current
        let now = Date()
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = period.startHour
        startComponents.minute = period.startMinute
        startComponents.second = 0
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = period.endHour
        endComponents.minute = period.endMinute
        endComponents.second = 0
        
        guard let startTime = calendar.date(from: startComponents),
              let endTime = calendar.date(from: endComponents) else {
            return nil
        }
        
        return (startTime, endTime)
    }
    
    private func createClassTimeForDay(periodIndex: Int, daysToAdd: Int) -> (startTime: Date, endTime: Date)? {
        let periodTimes: [(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)] = [
            (8, 20, 9, 10), (9, 20, 10, 10), (10, 20, 11, 10), (11, 20, 12, 10),
            (13, 10, 14, 0), (14, 10, 15, 0), (15, 10, 16, 0)
        ]
        
        guard periodIndex >= 0 && periodIndex < periodTimes.count else {
            return nil
        }
        
        let period = periodTimes[periodIndex]
        let calendar = Calendar.current
        let now = Date()
        
        // 지정된 일수만큼 이후의 날짜
        guard let futureDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) else {
            return nil
        }
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: futureDate)
        startComponents.hour = period.startHour
        startComponents.minute = period.startMinute
        startComponents.second = 0
                
                var endComponents = calendar.dateComponents([.year, .month, .day], from: futureDate)
                endComponents.hour = period.endHour
                endComponents.minute = period.endMinute
                endComponents.second = 0
                
                guard let startTime = calendar.date(from: startComponents),
                      let endTime = calendar.date(from: endComponents) else {
                    return nil
                }
                
                return (startTime, endTime)
            }
            
            // 과목명 표시 (탐구반 커스텀 적용)
            private func getDisplaySubject(scheduleItem: ScheduleItem) -> String {
                var displaySubject = scheduleItem.subject
                
                if scheduleItem.subject.contains("반") {
                    let customKey = "selected\(scheduleItem.subject)Subject"
                    
                    if let selectedSubject = sharedDefaults.string(forKey: customKey),
                       selectedSubject != "선택 없음" && selectedSubject != scheduleItem.subject {
                        
                        let components = selectedSubject.components(separatedBy: "/")
                        if components.count == 2 {
                            displaySubject = components[0]
                        }
                    }
                }
                
                return displaySubject
            }
            
            // 교실 정보 표시 (탐구반 커스텀 적용)
            private func getDisplayLocation(scheduleItem: ScheduleItem) -> String {
                var displayLocation = scheduleItem.teacher
                
                if scheduleItem.subject.contains("반") {
                    let customKey = "selected\(scheduleItem.subject)Subject"
                    
                    if let selectedSubject = sharedDefaults.string(forKey: customKey),
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
