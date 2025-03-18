import SwiftUI

struct TimeTableTab: View {
    // 특별실 Wi-Fi 정보 정의
    private let specialRooms: [String: SpecialRoomWiFi] = [
        "화학생명실": SpecialRoomWiFi(name: "화학생명실", ssid: "화학생명실", password: "yangcheon401"),
        "홈베이스": SpecialRoomWiFi(name: "홈베이스A/B", ssid: "홈베이스", password: "yangcheon402"),
        "홈베이스A": SpecialRoomWiFi(name: "홈베이스A/B", ssid: "홈베이스", password: "yangcheon402"),
        "홈베이스B": SpecialRoomWiFi(name: "홈베이스A/B", ssid: "홈베이스", password: "yangcheon402"),
        "음악실": SpecialRoomWiFi(name: "음악실", ssid: "음악실", password: "yangcheon403"),
        "소강당": SpecialRoomWiFi(name: "소강당", ssid: "소강당", password: "yangcheon404"),
        "미술실": SpecialRoomWiFi(name: "미술실", ssid: "미술실", password: "yangcheon405"),
        "물리지학실": SpecialRoomWiFi(name: "물리지학실", ssid: "물리지학실", password: "yangcheon406"),
        "멀티스튜디오": SpecialRoomWiFi(name: "멀티스튜디오", ssid: "멀티스튜디오", password: "yangcheon407"),
        "다목적실": SpecialRoomWiFi(name: "다목적실A/B", ssid: "다목적실AB", password: "yangcheon408"),
        "다목적실A": SpecialRoomWiFi(name: "다목적실A/B", ssid: "다목적실AB", password: "yangcheon408"),
        "다목적실B": SpecialRoomWiFi(name: "다목적실A/B", ssid: "다목적실AB", password: "yangcheon408"),
        "꿈담카페A": SpecialRoomWiFi(name: "꿈담카페A", ssid: "꿈담카페A", password: "yangcheon409"),
        "꿈담카페B": SpecialRoomWiFi(name: "꿈담카페B", ssid: "꿈담카페B", password: "yangcheon410"),
        "도서실": SpecialRoomWiFi(name: "도서실", ssid: "도서실", password: "yangcheon411"),
        "세미나실": SpecialRoomWiFi(name: "세미나실", ssid: "세미나실", password: "yangcheon412"),
        "상록실": SpecialRoomWiFi(name: "상록실", ssid: "상록실", password: "yangcheon413")
    ]
    @StateObject private var viewModel = ScheduleViewModel()
    @ObservedObject private var notificationManager = LocalNotificationManager.shared
    
    // 시간표 표시를 위한 선택된 학년/반 (UserDefaults에서 초기값을 가져오되, 변경해도 UserDefaults를 업데이트하지 않음)
    @State private var displayGrade: Int = 0
    @State private var displayClass: Int = 0
    
    // 초기화 시 값을 설정
    private func initializeDefaultValues() {
        displayGrade = UserDefaults.standard.integer(forKey: "defaultGrade")
        displayClass = UserDefaults.standard.integer(forKey: "defaultClass")
        
        // 값이 0인 경우 기본값 설정
        if displayGrade == 0 {
            displayGrade = 1
        }
        if displayClass == 0 {
            displayClass = 1
        }
    }
    
    // 현재 수업과 와이파이 관련 상태 추가
    @State private var currentClass: ScheduleItem?
    @State private var wifiConnectionTarget: (grade: Int, classNumber: Int)?
    @State private var specialRoomWifi: SpecialRoomWiFi?
    @State private var showWifiConnectionButton: Bool = false
    @State private var isConnecting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var connectionType: ConnectionType = .regularClass
    
    // 실제 알림에 사용되는 설정값 (참조용)
    private var actualGrade: Int {
        UserDefaults.standard.integer(forKey: "defaultGrade")
    }
    
    private var actualClass: Int {
        UserDefaults.standard.integer(forKey: "defaultClass")
    }
    
    // 기본 셀 배경색
    @State private var cellBackgroundColor: Color = Color.yellow.opacity(0.3)
    
    let daysOfWeek = [NSLocalizedString("Mon", comment: ""), NSLocalizedString("Tue", comment: ""), NSLocalizedString("Wed", comment: ""), NSLocalizedString("Thu", comment: ""), NSLocalizedString("Fri", comment: "")]
    let periodTimes = [
        ("08:20", "09:10"), ("09:20", "10:10"), ("10:20", "11:10"), ("11:20", "12:10"),
        ("13:10", "14:00"), ("14:10", "15:00"), ("15:10", "16:00")
    ]
    
    // 타이머를 사용하여 현재 수업 정보 업데이트 (30초마다)
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    // 연결 타입 열거형
    enum ConnectionType {
        case regularClass        // 일반 교실 (학년-반)
        case specialRoom         // 특별실 (화학실, 음악실 등)
        case roomNumber          // 교실 번호 (302, 401 등)
    }
    
    // 시간표 헤더 뷰
    private func TimeTableHeaderView() -> some View {
        HStack {
            Picker(NSLocalizedString("Grade", comment: ""), selection: $displayGrade) {
                ForEach(1..<4) { grade in
                    Text(String(format: NSLocalizedString("GradeP", comment: ""), grade)).tag(grade)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: displayGrade) { _ in
                viewModel.loadSchedule(grade: displayGrade, classNumber: displayClass)
            }

            Picker(NSLocalizedString("Class", comment: ""), selection: $displayClass) {
                ForEach(1..<12) { classNumber in
                    Text(String(format: NSLocalizedString("ClassP", comment: ""), classNumber)).tag(classNumber)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: displayClass) { _ in
                viewModel.loadSchedule(grade: displayGrade, classNumber: displayClass)
            }
            
            Button(action: {
                viewModel.loadSchedule(grade: displayGrade, classNumber: displayClass)
                loadCellBackgroundColor()
                updateCurrentClassInfo()
            }) {
                Image(systemName: "clock.arrow.circlepath")
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
    
    // 시간표 정보 헤더 뷰
    private func TimeTableInfoView() -> some View {
        Group {
            if displayGrade != actualGrade || displayClass != actualClass {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("현재 표시: \(displayGrade)학년 \(displayClass)반 | 알림 설정: \(actualGrade)학년 \(actualClass)반")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                Button(action: {
                    // 현재 표시 중인 학년/반으로 알림 설정 업데이트
                    UserDefaults.standard.set(displayGrade, forKey: "defaultGrade")
                    UserDefaults.standard.set(displayClass, forKey: "defaultClass")
                    
                    // 알림 재설정
                    if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
                        LocalNotificationManager.shared.fetchAndSaveSchedule(grade: displayGrade, classNumber: displayClass)
                    }
                }) {
                    Text("이 시간표로 알림 설정하기")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // Wi-Fi 연결 뷰
    private func WiFiConnectionView() -> some View {
        Group {
            if showWifiConnectionButton {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundColor(.blue)
                        if let currentClass = currentClass {
                            // 작은 폰트 사이즈로 조정
                            Text("현재 \(currentClass.subject) 수업 중")
                                .font(.system(size: 14))
                            if !currentClass.teacher.isEmpty && !currentClass.teacher.contains("T") {
                                Text("교실: \(currentClass.teacher)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // 연결 유형에 따라 다른 버튼 표시
                    WiFiConnectionButtonView()
                }
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
    
    // Wi-Fi 연결 버튼 뷰
    private func WiFiConnectionButtonView() -> some View {
        Group {
            switch connectionType {
            case .regularClass:
                if let target = wifiConnectionTarget {
                    Button(action: {
                        connectToWiFi(grade: target.grade, classNumber: target.classNumber)
                    }) {
                        HStack {
                            Image(systemName: "network")
                            Text("\(target.grade)학년 \(target.classNumber)반 Wi-Fi 연결하기")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isConnecting)
                    .padding(.horizontal)
                }
                
            case .specialRoom:
                if let specialRoom = specialRoomWifi {
                    Button(action: {
                        connectToSpecialRoomWiFi(specialRoom: specialRoom)
                    }) {
                        HStack {
                            Image(systemName: "network")
                            Text("\(specialRoom.name) Wi-Fi 연결하기")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isConnecting)
                    .padding(.horizontal)
                }
                
            case .roomNumber:
                if let target = wifiConnectionTarget {
                    Button(action: {
                        connectToWiFi(grade: target.grade, classNumber: target.classNumber)
                    }) {
                        HStack {
                            Image(systemName: "network")
                            Text("\(target.grade)학년 \(target.classNumber)반 Wi-Fi 연결하기")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isConnecting)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // 시간표 그리드 뷰
    private func TimeTableGridView(geometry: GeometryProxy) -> some View {
        let cellWidth = (geometry.size.width - geometry.safeAreaInsets.leading - geometry.safeAreaInsets.trailing) / 6
        let cellHeight = geometry.size.height / 8
        let cellSize = min(cellWidth, cellHeight)

        return VStack(spacing: 0) {
            ForEach(0..<8) { row in
                HStack(spacing: 0) {
                    ForEach(0..<6) { col in
                        TimeTableCellView(row: row, col: col, cellSize: cellSize)
                    }
                }
            }
        }
        .frame(width: cellSize * 6, height: cellSize * 8)
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        .clipped()
    }
    
    // 시간표 셀 뷰
    private func TimeTableCellView(row: Int, col: Int, cellSize: CGFloat) -> some View {
        GeometryReader { cellGeometry in
            let isHeader = row == 0 || col == 0
            let textColor = Color.primary
            
            ZStack {
                // 배경색
                if isHeader {
                    Color.gray.opacity(0.3)
                } else {
                    if self.isCurrentPeriod(row: row, col: col) {
                        cellBackgroundColor
                    } else {
                        Color.clear
                    }
                }
                
                // 셀 내용
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
                    TimeTableCellContentView(row: row, col: col, cellSize: cellSize)
                }
            }
        }
    }
    
    // 시간표 셀 내용 뷰
    private func TimeTableCellContentView(row: Int, col: Int, cellSize: CGFloat) -> some View {
        let schedule = viewModel.schedules[safe: col - 1]?[safe: row - 1]
        
        return VStack {
            if let subject = schedule?.subject {
                if subject.contains("반") {
                    // A반, B반 등의 반으로 표시된 과목은 UserDefaults에서 선택한 과목으로 대체
                    let selectedSubject = UserDefaults.standard.string(forKey: "selected\(subject)Subject") ?? subject
                    
                    if selectedSubject != subject && selectedSubject != "선택 없음" {
                        // 과목명/장소 분리하여 표시
                        let components = selectedSubject.components(separatedBy: "/")
                        if components.count == 2 {
                            Text(components[0])
                                .font(.system(size: 14))
                                .lineLimit(1)
                            Text(components[1])
                                .font(.system(size: 10))
                                .lineLimit(1)
                        } else {
                            Text(selectedSubject)
                                .font(.system(size: 14))
                        }
                    } else {
                        Text(subject)
                            .font(.system(size: 14))
                            .lineLimit(1)
                        Text(schedule?.teacher ?? "")
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                } else {
                    // 기존의 과목명 표시 유지
                    Text(subject)
                        .font(.system(size: 14))
                        .lineLimit(1)
                    Text(schedule?.teacher ?? "")
                        .font(.system(size: 10))
                        .lineLimit(1)
                }
            } else {
                Text("")
            }
        }
        .frame(width: cellSize, height: cellSize)
        .border(Color.primary)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 시간표 헤더
                TimeTableHeaderView()
                
                // 시간표 정보
                TimeTableInfoView()

                // 현재 수업에 대한 와이파이 연결 버튼
                WiFiConnectionView()

                Spacer()
                
                // 시간표 그리드
                GeometryReader { geometry in
                    TimeTableGridView(geometry: geometry)
                }
                .padding([.leading, .trailing], 0)
                .padding(.top, 10)
                .padding(.bottom, 10)

                Spacer()
            }
            .navigationBarTitle(NSLocalizedString("TimeTable", comment: ""), displayMode: .inline)
            .onAppear {
                // 초기값 설정
                initializeDefaultValues()
                
                // 셀 배경색 로드
                loadCellBackgroundColor()
                
                // 시간표 로드
                viewModel.loadSchedule(grade: displayGrade, classNumber: displayClass)
                
                // 로컬 저장된 시간표 확인 및 필요시 서버에서 새로 가져오기
                if LocalNotificationManager.shared.loadLocalSchedule() == nil {
                    ScheduleManager.shared.fetchAndUpdateSchedule(grade: actualGrade, classNumber: actualClass) { _ in
                        // 완료 시 처리 (필요하면 구현)
                    }
                }
                
                // 현재 수업 정보 업데이트
                updateCurrentClassInfo()
            }
            .onReceive(timer) { _ in
                // 1분마다 현재 수업 정보 업데이트
                updateCurrentClassInfo()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인"))
                )
            }
            .overlay(
                Group {
                    if isConnecting {
                        ZStack {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                                Text("Wi-Fi 연결 중...")
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                        }
                    }
                }
            )
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
        
        // Check if during current class period
        if now >= startOfPeriod && now <= endOfPeriod && weekday == col - 1 {
            return true
        }
        
        // Check if during break time before next class
        if periodIndex < periodTimes.count - 1 {
            let nextPeriodIndex = periodIndex + 1
            let (nextStartTimeString, _) = periodTimes[nextPeriodIndex]
            
            guard let nextStartTime = formatter.date(from: nextStartTimeString) else {
                return false
            }
            
            let nextStartComponents = calendar.dateComponents([.hour, .minute], from: nextStartTime)
            let startOfNextPeriod = calendar.date(bySettingHour: nextStartComponents.hour!, minute: nextStartComponents.minute!, second: 0, of: now)!
            
            // If it's break time, highlight the next class
            if now > endOfPeriod && now < startOfNextPeriod && row == nextPeriodIndex + 1 && weekday == col - 1 {
                return true
            }
        }
        
        return false
    }

    // 셀 배경색 로드
    private func loadCellBackgroundColor() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "cellBackgroundColor") {
            do {
                if let uiColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
                    cellBackgroundColor = Color(uiColor)
                }
            } catch {
                print("배경색 로드 오류: \(error)")
                cellBackgroundColor = Color.yellow.opacity(0.3)
            }
        } else {
            cellBackgroundColor = Color.yellow.opacity(0.3)
        }
    }
    
    // MARK: - 현재 수업 정보 및 Wi-Fi 연결 관련 함수
    
    /// 현재 시간의 수업 정보를 업데이트하고 Wi-Fi 연결 버튼 표시 여부를 결정하는 함수
    private func updateCurrentClassInfo() {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now) - 2 // 일요일: 1, 월요일: 2, ..., 금요일: 6
        
        // 주말이거나 시간표 정보가 없는 경우
        if weekday < 0 || weekday > 4 || viewModel.schedules.isEmpty {
            showWifiConnectionButton = false
            return
        }
        
        // 현재 교시 확인
        var currentPeriodIndex: Int = -1
        var isPreClassTime: Bool = false // 수업 10분 전 여부
        
        for (index, period) in periodTimes.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            
            guard let startTime = formatter.date(from: period.0),
                  let endTime = formatter.date(from: period.1) else {
                continue
            }
            
            let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
            
            // 수업 시작 10분 전 계산
            var preClassComponents = startComponents
            if startComponents.minute! >= 10 {
                preClassComponents.minute = startComponents.minute! - 10
            } else {
                if startComponents.hour! > 0 {
                    preClassComponents.hour = startComponents.hour! - 1
                    preClassComponents.minute = startComponents.minute! + 50 // 60 - 10
                }
            }
            
            let preClassTime = calendar.date(bySettingHour: preClassComponents.hour!, minute: preClassComponents.minute!, second: 0, of: now)!
            let startOfPeriod = calendar.date(bySettingHour: startComponents.hour!, minute: startComponents.minute!, second: 0, of: now)!
            let endOfPeriod = calendar.date(bySettingHour: endComponents.hour!, minute: endComponents.minute!, second: 0, of: now)!
            
            // 수업 시간 또는 수업 10분 전인지 확인
            if now >= startOfPeriod && now <= endOfPeriod {
                currentPeriodIndex = index
                isPreClassTime = false
                break
            } else if now >= preClassTime && now < startOfPeriod {
                currentPeriodIndex = index
                isPreClassTime = true
                break
            }
        }
        
        // 수업 시간이 아닌 경우
        if currentPeriodIndex == -1 {
            showWifiConnectionButton = false
            return
        }
        
        // 현재 수업 정보 가져오기
        guard let daySchedule = viewModel.schedules[safe: weekday],
              let currentClassInfo = daySchedule[safe: currentPeriodIndex] else {
            showWifiConnectionButton = false
            return
        }
        
        // 1교시 특별 처리 (8시 10분부터)
        if currentPeriodIndex == 0 && !isPreClassTime {
            let components = calendar.dateComponents([.hour, .minute], from: now)
            if let hour = components.hour, let minute = components.minute {
                if hour == 8 && minute < 10 {
                    showWifiConnectionButton = false
                    return
                }
            }
        }
        
        // 수업 정보 업데이트
        self.currentClass = currentClassInfo
        
        // Wi-Fi 연결 대상 결정
        determineWiFiConnectionTarget(currentClassInfo: currentClassInfo)
    }
    
    /// 현재 수업 정보를 바탕으로 Wi-Fi 연결 대상 결정
    private func determineWiFiConnectionTarget(currentClassInfo: ScheduleItem) {
        // 과목이 없는 경우 (자습 시간 등)
        if currentClassInfo.subject.isEmpty {
            showWifiConnectionButton = false
            return
        }
        
        // 정보 수업은 와이파이 정보 표시하지 않음
        if currentClassInfo.subject.contains("정보") {
            showWifiConnectionButton = false
            return
        }
        
        var targetGrade = actualGrade
        var targetClass = actualClass
        var shouldShowButton = true
        self.connectionType = .regularClass
        
        // 교실 위치 확인 (teacher 필드에 교실 정보가 있는지)
        if !currentClassInfo.teacher.contains("T") {
            // 'T'가 없는 경우 - 특별실 또는 탐구 과목

            // 교실 번호가 3자리 숫자인지 확인 (예: "302", "401" 등)
            let roomNumber = currentClassInfo.teacher.trimmingCharacters(in: .whitespaces)
            if roomNumber.count == 3, let roomNum = Int(roomNumber) {
                // 첫 번째 숫자가 학년, 나머지 두 숫자가 반 번호
                let roomGrade = roomNum / 100
                let roomClass = roomNum % 100
                
                // 유효한 학년/반 번호인지 확인
                if roomGrade >= 1 && roomGrade <= 3 && roomClass >= 1 && roomClass <= 11 {
                    targetGrade = roomGrade
                    targetClass = roomClass
                    self.connectionType = .roomNumber
                }
            } else {
                // 특별실 확인
                checkForSpecialRoom(currentClassInfo: currentClassInfo)
            }
        } else {
            // 1, 2학년에서 미술, 음악, 창독 과목 특별 처리
            let grade = currentClassInfo.grade
            if grade == 1 || grade == 2 {
                if currentClassInfo.subject == "미술" || currentClassInfo.subject.contains("미술") {
                    if let specialRoom = specialRooms["미술실"] {
                        self.specialRoomWifi = specialRoom
                        self.connectionType = .specialRoom
                        shouldShowButton = true
                    }
                } else if currentClassInfo.subject == "음악" || currentClassInfo.subject.contains("음악") {
                    if let specialRoom = specialRooms["음악실"] {
                        self.specialRoomWifi = specialRoom
                        self.connectionType = .specialRoom
                        shouldShowButton = true
                    }
                } else if currentClassInfo.subject == "창독" || currentClassInfo.subject.contains("창독") {
                    if let specialRoom = specialRooms["도서실"] {
                        self.specialRoomWifi = specialRoom
                        self.connectionType = .specialRoom
                        shouldShowButton = true
                    }
                }
            }
        }
        
        // 연결 유형에 따라 설정
        if self.connectionType == .regularClass || self.connectionType == .roomNumber {
            self.wifiConnectionTarget = (grade: targetGrade, classNumber: targetClass)
        }
        
        self.showWifiConnectionButton = shouldShowButton
    }
    
    /// 특별실 여부 확인 및 처리
    private func checkForSpecialRoom(currentClassInfo: ScheduleItem) {
        let roomName = currentClassInfo.teacher.trimmingCharacters(in: .whitespaces)
        
        // 홈베이스A/B, 다목적실A/B 처리
        if roomName.contains("홈베이스") || roomName == "홈베이스A" || roomName == "홈베이스B" {
            if let specialRoom = specialRooms["홈베이스"] {
                self.specialRoomWifi = specialRoom
                self.connectionType = .specialRoom
                self.showWifiConnectionButton = true
                return
            }
        } else if roomName.contains("다목적실") || roomName == "다목적실A" || roomName == "다목적실B" {
            if let specialRoom = specialRooms["다목적실"] {
                self.specialRoomWifi = specialRoom
                self.connectionType = .specialRoom
                self.showWifiConnectionButton = true
                return
            }
        } else if roomName == "꿈담카페A" {
            if let specialRoom = specialRooms["꿈담카페A"] {
                self.specialRoomWifi = specialRoom
                self.connectionType = .specialRoom
                self.showWifiConnectionButton = true
                return
            }
        } else if roomName == "꿈담카페B" {
            if let specialRoom = specialRooms["꿈담카페B"] {
                self.specialRoomWifi = specialRoom
                self.connectionType = .specialRoom
                self.showWifiConnectionButton = true
                return
            }
        } else {
            // 기타 특별실 확인
            for (key, specialRoom) in specialRooms {
                if roomName.contains(key) {
                    self.specialRoomWifi = specialRoom
                    self.connectionType = .specialRoom
                    self.showWifiConnectionButton = true
                    return
                }
            }
        }
        
        // 특별실이 아닌 경우
        self.showWifiConnectionButton = false
    }
    
    /// Wi-Fi 연결 함수 - 일반 교실
    private func connectToWiFi(grade: Int, classNumber: Int) {
        isConnecting = true
        
        WiFiConnectionManager.shared.connectToWiFi(grade: grade, classNumber: classNumber) { success, message in
            isConnecting = false
            
            if success {
                self.alertTitle = "연결 성공"
                self.alertMessage = message
            } else {
                self.alertTitle = "연결 오류"
                self.alertMessage = message
            }
            
            self.showAlert = true
        }
    }
    
    /// Wi-Fi 연결 함수 - 특별실
    private func connectToSpecialRoomWiFi(specialRoom: SpecialRoomWiFi) {
        isConnecting = true
        
        WiFiConnectionManager.shared.connectToSpecialRoomWiFi(ssid: specialRoom.ssid, password: specialRoom.password) { success, message in
            isConnecting = false
            
            if success {
                self.alertTitle = "연결 성공"
                self.alertMessage = message
            } else {
                self.alertTitle = "연결 오류"
                self.alertMessage = message
            }
            
            self.showAlert = true
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
