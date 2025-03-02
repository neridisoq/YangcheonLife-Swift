import SwiftUI

struct TimeTableTab: View {
    @StateObject private var viewModel = ScheduleViewModel()
    @ObservedObject private var notificationManager = LocalNotificationManager.shared
    @State private var selectedGrade: Int = UserDefaults.standard.integer(forKey: "defaultGrade")
    @State private var selectedClass: Int = UserDefaults.standard.integer(forKey: "defaultClass")
    @State private var cellBackgroundColor: Color = {
        if let data = UserDefaults.standard.data(forKey: "cellBackgroundColor"),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            return Color(uiColor)
        }
        return Color.yellow.opacity(0.3)
    }()
    
    let daysOfWeek = [NSLocalizedString("Mon", comment: ""), NSLocalizedString("Tue", comment: ""), NSLocalizedString("Wed", comment: ""), NSLocalizedString("Thu", comment: ""), NSLocalizedString("Fri", comment: "")]
    let periodTimes = [
        ("08:20", "09:10"), ("09:20", "10:10"), ("10:20", "11:10"), ("11:20", "12:10"),
        ("13:10", "14:00"), ("14:10", "15:00"), ("15:10", "16:00")
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Picker(NSLocalizedString("Grade", comment: ""), selection: $selectedGrade) {
                        ForEach(1..<4) { grade in
                            Text(String(format: NSLocalizedString("GradeP", comment: ""), grade)).tag(grade)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedGrade) { _ in
                        viewModel.loadSchedule(grade: selectedGrade, classNumber: selectedClass)
                    }

                    Picker(NSLocalizedString("Class", comment: ""), selection: $selectedClass) {
                        ForEach(1..<12) { classNumber in
                            Text(String(format: NSLocalizedString("ClassP", comment: ""), classNumber)).tag(classNumber)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedClass) { _ in
                        viewModel.loadSchedule(grade: selectedGrade, classNumber: selectedClass)
                    }
                    
                    Button(action: {
                        viewModel.loadSchedule(grade: selectedGrade, classNumber: selectedClass)
                        loadCellBackgroundColor()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding()

                Spacer()
                
                GeometryReader { geometry in
                    let cellWidth = (geometry.size.width - geometry.safeAreaInsets.leading - geometry.safeAreaInsets.trailing) / 6
                    let cellHeight = geometry.size.height / 8
                    let cellSize = min(cellWidth, cellHeight)

                    VStack(spacing: 0) {
                        ForEach(0..<8) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<6) { col in
                                    GeometryReader { cellGeometry in
                                        let isHeader = row == 0 || col == 0
                                        let textColor = Color.primary
                                        
                                        ZStack {
                                            if isHeader {
                                                Color.gray.opacity(0.3)
                                            } else {
                                                if self.isCurrentPeriod(row: row, col: col) {
                                                    cellBackgroundColor
                                                } else {
                                                    Color.clear
                                                }
                                            }
                                            
                                            if row == 0 && col == 0 {
                                                Text(" ")
                                                    .frame(width: cellSize, height: cellSize)
                                                    .foregroundColor(textColor)
                                                    .border(Color.primary)
                                            } else if row == 0 {
                                                Text(self.daysOfWeek[col - 1])
                                                    .frame(width: cellSize, height: cellSize)
                                                    .foregroundColor(textColor)
                                                    .border(Color.primary)
                                            } else if col == 0 {
                                                VStack {
                                                    Text(String(format: NSLocalizedString("period", comment: ""), row))
                                                        .font(.system(size: 14))
                                                    Text(self.periodTimes[row - 1].0)
                                                        .font(.system(size: 10))
                                                }
                                                .frame(width: cellSize, height: cellSize)
                                                .foregroundColor(textColor)
                                                .border(Color.primary)
                                            } else {
                                                let schedule = viewModel.schedules[safe: col - 1]?[safe: row - 1]
                                                VStack {
                                                    // 시간표 셀 내용 표시 부분
                                                    if let subject = schedule?.subject {
                                                        if subject.contains("반") {
                                                            // A반, B반 등의 반으로 표시된 과목은 UserDefaults에서 선택한 과목으로 대체
                                                            let selectedSubject = UserDefaults.standard.string(forKey: "selected\(subject)Subject") ?? subject
                                                            
                                                            if selectedSubject != subject && selectedSubject != "선택 없음" {
                                                                // 과목명/장소 분리하여 표시
                                                                let components = selectedSubject.components(separatedBy: "/")
                                                                if components.count == 2 {
                                                                    Text(components[0])
                                                                        .font(.system(size: 16))
                                                                        .lineLimit(1)
                                                                    Text(components[1])
                                                                        .font(.system(size: 12))
                                                                        .lineLimit(1)
                                                                } else {
                                                                    Text(selectedSubject)
                                                                }
                                                            } else {
                                                                Text(subject)
                                                                    .font(.system(size: 16))
                                                                    .lineLimit(1)
                                                                Text(schedule?.teacher ?? "")
                                                                    .font(.system(size: 12))
                                                                    .lineLimit(1)
                                                            }
                                                        } else {
                                                            // 기존의 과목명 표시 유지
                                                            Text(subject)
                                                                .font(.system(size: 16))
                                                                .lineLimit(1)
                                                            Text(schedule?.teacher ?? "")
                                                                .font(.system(size: 12))
                                                                .lineLimit(1)
                                                        }
                                                    } else {
                                                        Text("")
                                                    }
                                                }
                                                .frame(width: cellSize, height: cellSize)
                                                .border(Color.primary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: cellSize * 6, height: cellSize * 8)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .clipped()
                }
                .padding([.leading, .trailing], 0)
                .padding(.top, 10)
                .padding(.bottom, 10)

                Spacer()
            }
            .navigationBarTitle(NSLocalizedString("TimeTable", comment: ""), displayMode: .inline)
            .onAppear {
                viewModel.loadSchedule(grade: selectedGrade, classNumber: selectedClass)
                loadCellBackgroundColor()
                
                // 로컬 저장된 시간표 확인 및 필요시 서버에서 새로 가져오기
                if LocalNotificationManager.shared.loadLocalSchedule() == nil {
                    LocalNotificationManager.shared.fetchAndSaveSchedule(grade: selectedGrade, classNumber: selectedClass)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func isCurrentPeriod(row: Int, col: Int) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now) - 2 // 일요일: 1, 월요일: 2, ..., 금요일: 6
        if weekday < 0 || weekday > 4 || row == 0 || col == 0 {
            return false
        }
        
        let periodIndex = row - 1
        let (startTimeString, endTimeString) = periodTimes[periodIndex]
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let startTime = formatter.date(from: startTimeString),
              let endTime = formatter.date(from: endTimeString) else {
            return false
        }
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        let startOfPeriod = calendar.date(bySettingHour: startComponents.hour!, minute: startComponents.minute!, second: 0, of: now)!
        let endOfPeriod = calendar.date(bySettingHour: endComponents.hour!, minute: endComponents.minute!, second: 0, of: now)!
        
        return now >= startOfPeriod && now <= endOfPeriod && weekday == col - 1
    }

    private func loadCellBackgroundColor() {
        if let data = UserDefaults.standard.data(forKey: "cellBackgroundColor"),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            cellBackgroundColor = Color(uiColor)
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct TimeTableTab_Previews: PreviewProvider {
    static var previews: some View {
        TimeTableTab()
            .environment(\.colorScheme, .dark) // 미리보기 다크 모드
        TimeTableTab()
            .environment(\.colorScheme, .light) // 미리보기 라이트 모드
    }
}
