// ScheduleGridView.swift - 시간표 그리드 뷰
import SwiftUI

struct ScheduleGridView: View {
    
    // MARK: - Properties
    let scheduleData: ScheduleData?
    let grade: Int
    let classNumber: Int
    let cellBackgroundColor: Color
    let geometry: GeometryProxy
    
    // MARK: - Private Properties
    private let totalPeriods = AppConstants.School.totalPeriods
    
    // MARK: - Computed Properties
    private var cellWidth: CGFloat {
        (geometry.size.width - geometry.safeAreaInsets.leading - geometry.safeAreaInsets.trailing) / 6
    }
    
    private var cellHeight: CGFloat {
        geometry.size.height / 8
    }
    
    private var cellSize: CGFloat {
        min(cellWidth, cellHeight)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { column in
                        ScheduleCellView(
                            row: row,
                            column: column,
                            cellSize: cellSize,
                            scheduleData: scheduleData,
                            cellBackgroundColor: cellBackgroundColor
                        )
                    }
                }
            }
        }
        .frame(width: cellSize * 6, height: cellSize * 8)
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        .clipped()
    }
}

// MARK: - 시간표 셀 뷰
struct ScheduleCellView: View {
    
    // MARK: - Properties
    let row: Int
    let column: Int
    let cellSize: CGFloat
    let scheduleData: ScheduleData?
    let cellBackgroundColor: Color
    
    // MARK: - State
    @StateObject private var viewModel = ScheduleTabViewModel()
    
    // MARK: - Computed Properties
    private var isHeader: Bool {
        row == 0 || column == 0
    }
    
    private var isCurrentPeriod: Bool {
        guard !isHeader,
              let scheduleData = scheduleData else { return false }
        
        return viewModel.isCurrentPeriod(weekday: column - 1, period: row)
    }
    
    private var scheduleItem: ScheduleItem? {
        guard !isHeader,
              let scheduleData = scheduleData,
              column - 1 >= 0,
              column - 1 < scheduleData.weeklySchedule.count,
              row - 1 >= 0,
              row - 1 < scheduleData.weeklySchedule[column - 1].count else {
            return nil
        }
        
        return scheduleData.weeklySchedule[column - 1][safe: row - 1]
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 배경색
            cellBackground
            
            // 셀 내용
            cellContent
        }
        .frame(width: cellSize, height: cellSize)
        .border(Color.primary, width: 1)
    }
    
    // MARK: - View Components
    
    /// 셀 배경
    @ViewBuilder
    private var cellBackground: some View {
        if isHeader {
            Color.headerBackground
        } else if isCurrentPeriod {
            cellBackgroundColor
        } else {
            Color.clear
        }
    }
    
    /// 셀 내용
    @ViewBuilder
    private var cellContent: some View {
        if row == 0 && column == 0 {
            // 좌상단 빈 셀
            Text("")
                .foregroundColor(.primary)
        } else if row == 0 {
            // 요일 헤더
            Text(AppConstants.School.weekdays[safe: column - 1] ?? "")
                .font(.system(size: 14))
                .foregroundColor(.primary)
        } else if column == 0 {
            // 교시 헤더
            VStack(spacing: 2) {
                Text("\(row)교시")
                    .font(.system(size: 12))
                
                if let timeString = getTimeString(for: row) {
                    Text(timeString)
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(.primary)
        } else {
            // 수업 내용 셀
            scheduleContentCell
        }
    }
    
    /// 수업 내용 셀
    @ViewBuilder
    private var scheduleContentCell: some View {
        VStack(spacing: 2) {
            if let item = scheduleItem {
                // 과목명 (탐구과목 치환 적용)
                Text(viewModel.getDisplaySubject(for: item))
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .fontWeight(isCurrentPeriod ? .bold : .regular)
                
                // 교실 정보 (탐구과목 치환 적용)
                Text(viewModel.getDisplayClassroom(for: item))
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            } else {
                Text("")
            }
        }
        .foregroundColor(isCurrentPeriod ? .primary : .primary)
    }
    
    // MARK: - Helper Methods
    
    /// 교시별 시간 문자열 가져오기
    private func getTimeString(for period: Int) -> String? {
        guard period >= 1 && period <= AppConstants.School.periodTimeStrings.count else {
            return nil
        }
        
        let timeInfo = AppConstants.School.periodTimeStrings[period - 1]
        return timeInfo.0 // 시작 시간만 표시
    }
}

// MARK: - 미리보기
struct ScheduleGridView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            ScheduleGridView(
                scheduleData: createSampleScheduleData(),
                grade: 3,
                classNumber: 5,
                cellBackgroundColor: .currentPeriodBackground,
                geometry: geometry
            )
        }
        .previewDisplayName("시간표 그리드")
    }
    
    static func createSampleScheduleData() -> ScheduleData {
        let sampleSchedule = [
            [
                ScheduleItem(grade: 3, classNumber: 5, weekday: 0, weekdayString: "월", period: 1, classroom: "301", subject: "수학"),
                ScheduleItem(grade: 3, classNumber: 5, weekday: 0, weekdayString: "월", period: 2, classroom: "301", subject: "영어"),
                ScheduleItem(grade: 3, classNumber: 5, weekday: 0, weekdayString: "월", period: 3, classroom: "체육관", subject: "체육"),
                ScheduleItem(grade: 3, classNumber: 5, weekday: 0, weekdayString: "월", period: 4, classroom: "301", subject: "국어"),
                ScheduleItem(grade: 3, classNumber: 5, weekday: 0, weekdayString: "월", period: 5, classroom: "302", subject: "사회"),
                ScheduleItem(grade: 3, classNumber: 5, weekday: 0, weekdayString: "월", period: 6, classroom: "303", subject: "과학"),
                ScheduleItem(grade: 3, classNumber: 5, weekday: 0, weekdayString: "월", period: 7, classroom: "301", subject: "진로")
            ]
        ]
        
        return ScheduleData(
            grade: 3,
            classNumber: 5,
            lastUpdated: Date(),
            weeklySchedule: sampleSchedule + Array(repeating: sampleSchedule[0], count: 4)
        )
    }
}