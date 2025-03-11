import WidgetKit
import SwiftUI

struct NextClassWidgetView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if case .mealInfo = entry.displayMode {} else {
                HStack {
                    Text("\(entry.grade)학년 \(entry.classNumber)반")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                }
                .padding(.bottom, 2)
            }
            
            switch entry.displayMode {
            case .nextClass(let nextClass):
                // 다음 수업 정보 표시
                VStack(alignment: .leading, spacing: 4) {
                    Text("다음 수업")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(nextClass.subject)")
                        .font(.system(size: 18, weight: .bold))
                        .lineLimit(1)
                    
                    Text("\(nextClass.teacher)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(formatTime(nextClass.startTime)) ~ \(formatTime(nextClass.endTime))")
                            .font(.caption2)
                        
                        Spacer()
                        
                        let remainingTime = nextClass.startTime.timeIntervalSince(entry.date)
                        Text(formatRemainingTime(remainingTime))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
            case .peInfo(let weekday, let hasPhysicalEducation):
                // 체육 수업 정보 표시
                VStack(alignment: .center, spacing: 4) {
                    Spacer()
                    
                    Image(systemName: hasPhysicalEducation ? "figure.run" : "figure.walk")
                        .font(.system(size: 28))
                        .foregroundColor(hasPhysicalEducation ? .blue : .gray)
                    
                    Text("\(weekdayString(weekday - 1)) 체육 \(hasPhysicalEducation ? "있음" : "없음")")
                        .font(.headline)
                        .foregroundColor(hasPhysicalEducation ? .blue : .gray)
                    
                    if hasPhysicalEducation {
                        Text("체육복을 준비하세요!")
                            .font(.subheadline)
                    } else {
                        Text("내일은 체육이 없습니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            
            case .mealInfo(let mealInfo):
                            // 급식 정보 표시 - 2열 4행 그리드 형태로 수정
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "fork.knife")
                                        .foregroundColor(.orange)
                                    
                                    Text("\(mealInfo.mealType.name) 메뉴")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                    
                                    Text(mealInfo.calInfo)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // 메뉴 항목을 최대 8개(2열 4행)로 제한
                                let menuItems = getMenuItems(mealInfo.menuText, maxCount: 8)
                                
                                // 2열 4행 그리드 레이아웃
                                VStack(spacing: 4) {
                                    ForEach(0..<min(4, (menuItems.count + 1) / 2)) { rowIndex in
                                        HStack {
                                            // 왼쪽 열
                                            Text(rowIndex * 2 < menuItems.count ? menuItems[rowIndex * 2] : "")
                                                .font(.system(size: 13))
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            // 오른쪽 열
                                            Text(rowIndex * 2 + 1 < menuItems.count ? menuItems[rowIndex * 2 + 1] : "")
                                                .font(.system(size: 13))
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                
            case .noInfo:
                // 정보 없음
                Spacer()
                Text("다음 수업 정보 없음")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
        }
        .padding()
        .modifier(WidgetBackgroundModifier())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatRemainingTime(_ timeInterval: TimeInterval) -> String {
        if timeInterval < 0 {
            return "진행 중"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분 전"
        } else {
            return "\(minutes)분 전"
        }
    }
    private func getMenuItems(_ text: String, maxCount: Int) -> [String] {
            let items = text.split(separator: "\n")
                          .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                          .filter { !$0.isEmpty }
            return Array(items.prefix(maxCount))
        }
    // 메뉴 텍스트를 적절한 길이로 포맷팅하는 함수
    private func formatMenuText(_ text: String) -> [String] {
        // 원본 메뉴를 줄바꿈으로 분리
        let menuItems = text.split(separator: "\n").map { String($0) }
        var formattedLines: [String] = []
        var currentLine = ""
        let maxItemsPerLine = 4
        
        // 각 메뉴 항목별로 처리
        for (index, item) in menuItems.enumerated() {
            if index % maxItemsPerLine == 0 && !currentLine.isEmpty {
                formattedLines.append(currentLine)
                currentLine = ""
            }
            
            if currentLine.isEmpty {
                currentLine = item
            } else {
                currentLine += ", " + item
            }
        }
        
        // 마지막 라인 추가
        if !currentLine.isEmpty {
            formattedLines.append(currentLine)
        }
        
        return formattedLines
    }
    private func weekdayString(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "월요일"
        case 2: return "화요일"
        case 3: return "수요일"
        case 4: return "목요일"
        case 5: return "금요일"
        default: return ""
        }
    }
}

// 위젯 배경 모디파이어 - iOS 버전에 따라 적절한 배경 설정
struct WidgetBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
                    content
                        .containerBackground(.background, for: .widget)
                } else {
                    content
                        .background(Color(UIColor.systemBackground))
                }
            }
        }

        // 미리보기 제공자
        struct NextClassWidgetView_Previews: PreviewProvider {
            static var previews: some View {
                let previewDate = Date()
                let calendar = Calendar.current
                
                // 예시 수업 정보 생성
                let startTime = calendar.date(bySettingHour: 10, minute: 20, second: 0, of: previewDate)!
                let endTime = calendar.date(bySettingHour: 11, minute: 10, second: 0, of: previewDate)!
                
                let exampleClass = ClassInfo(
                    subject: "수학",
                    teacher: "302호",
                    periodIndex: 2,
                    startTime: startTime,
                    endTime: endTime
                )
                
                return Group {
                    // 다음 수업 미리보기
                    NextClassWidgetView(entry: NextClassEntry(
                        date: previewDate,
                        displayMode: .nextClass(exampleClass),
                        grade: 2,
                        classNumber: 5
                    ))
                    .previewContext(WidgetPreviewContext(family: .systemSmall))
                    .previewDisplayName("다음 수업")
                    
                    // 체육 정보 미리보기 (있음)
                    NextClassWidgetView(entry: NextClassEntry(
                        date: previewDate,
                        displayMode: .peInfo(weekday: 2, hasPhysicalEducation: true),
                        grade: 2,
                        classNumber: 5
                    ))
                    .previewContext(WidgetPreviewContext(family: .systemSmall))
                    .previewDisplayName("체육 있음")
                    
                    // 체육 정보 미리보기 (없음)
                    NextClassWidgetView(entry: NextClassEntry(
                        date: previewDate,
                        displayMode: .peInfo(weekday: 3, hasPhysicalEducation: false),
                        grade: 2,
                        classNumber: 5
                    ))
                    .previewContext(WidgetPreviewContext(family: .systemSmall))
                    .previewDisplayName("체육 없음")
                    
                    // 정보 없음 미리보기
                    NextClassWidgetView(entry: NextClassEntry(
                        date: previewDate,
                        displayMode: .noInfo,
                        grade: 2,
                        classNumber: 5
                    ))
                    .previewContext(WidgetPreviewContext(family: .systemSmall))
                    .previewDisplayName("정보 없음")
                }
            }
        }
