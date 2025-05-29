// ScheduleTabView.swift - 시간표 탭 메인 뷰
import SwiftUI

#if canImport(ActivityKit) && swift(>=5.9)
import ActivityKit
#endif

struct ScheduleTabView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var wifiService: WiFiService
    
    // MARK: - State Properties
    @StateObject private var viewModel = ScheduleTabViewModel()
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    @State private var showWiFiConnectionAlert = false
    @State private var wifiConnectionResult: WiFiConnectionResult?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer().frame(height: 10) // 상단 탭 이름과 학년/반 선택 박스 사이 간격 추가
                // 헤더 (학년/반 선택 및 새로고침)
                scheduleHeader
                
                // 시간표 정보 표시
                scheduleInfoSection
                Spacer().frame(height: 10) // 시간표 정보와 WiFi 제안 섹션 사이 간격 추가
                
                
                // WiFi 연결 제안
                if viewModel.isWifiSuggestionEnabled {
                wifiConnectionSection
                }
                Spacer().frame(height: 10) // WiFi 제안 섹션과 시간표 그리드 사이 간격 추가
                
                // 시간표 그리드
                scheduleGridSection
            }
            .navigationTitle(NSLocalizedString(LocalizationKeys.timeTable, comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.setupInitialValues()
                startPeriodicUpdate()
            }
            .onReceive(viewModel.timer) { _ in
                viewModel.updateCurrentClassInfo(scheduleData: scheduleService.currentScheduleData)
                
                // Live Activity 업데이트
                liveActivityManager.updateLiveActivity()
            }
            .loadingOverlay(isLoading: scheduleService.isLoading)
            .errorAlert(
                isPresented: .constant(scheduleService.lastError != nil),
                error: scheduleService.lastError
            )
            .alert("WiFi 연결", isPresented: $showWiFiConnectionAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                if let result = wifiConnectionResult {
                    Text(result.message)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - View Components
    
    
    /// 시간표 헤더 (학년/반 선택 및 새로고침)
    private var scheduleHeader: some View {
        HStack {
            Picker(NSLocalizedString("Grade", comment: ""), selection: $viewModel.displayGrade) {
                ForEach(AppConstants.School.grades, id: \.self) { grade in
                    Text(String(format: NSLocalizedString("GradeP", comment: ""), grade)).tag(grade)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: viewModel.displayGrade) { _ in
                loadScheduleData()
            }
            .frame(maxWidth: 120) // 학년 선택 크기 조정

            Picker(NSLocalizedString("Class", comment: ""), selection: $viewModel.displayClass) {
                ForEach(AppConstants.School.classes, id: \.self) { classNumber in
                    Text(String(format: NSLocalizedString("ClassP", comment: ""), classNumber)).tag(classNumber)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: viewModel.displayClass) { _ in
                loadScheduleData()
            }
            .frame(maxWidth: 120) // 반 선택 크기 조정
            
            Button(action: {
                Task {
                    await scheduleService.loadSchedule(
                        grade: viewModel.displayGrade,
                        classNumber: viewModel.displayClass,
                        forceRefresh: true
                    )
                    viewModel.updateCurrentClassInfo(scheduleData: scheduleService.currentScheduleData)
                    viewModel.loadCellBackgroundColor()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.appPrimary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    /// 시간표 정보 섹션
    @ViewBuilder
    private var scheduleInfoSection: some View {
        if viewModel.showDifferentGradeClassInfo {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.infoColor)
                    Text("현재 표시: \(viewModel.displayGrade)학년 \(viewModel.displayClass)반 | 알림 설정: \(viewModel.actualGrade)학년 \(viewModel.actualClass)반")
                        .captionStyle()
                    Spacer()
                }
                
                Button("이 시간표로 알림 설정하기") {
                    updateNotificationSettings()
                }
                .secondaryButtonStyle()
            }
            .appPadding()
        }
    }
    
    /// WiFi 연결 제안 섹션
    @ViewBuilder
    private var wifiConnectionSection: some View {
        if let connectionType = viewModel.suggestedWiFiConnection {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "wifi")
                        .foregroundColor(.appPrimary)
                    
                    if let currentClass = viewModel.currentClassInfo {
                        let currentStatus = TimeUtility.getCurrentPeriodStatus()
                        
                        switch currentStatus {
                        case .inClass(_):
                            // 아침자습이나 점심자습이면 수업 중이라는 표현을 사용하지 않음
                            if currentClass.subject == "아침자습" || currentClass.subject == "점심시간" {
                                Text("\(viewModel.getDisplaySubject(for: currentClass))")
                                    .bodyStyle()
                            } else {
                                Text("현재 \(viewModel.getDisplaySubject(for: currentClass)) 수업 중")
                                    .bodyStyle()
                            }
                        case .breakTime(_):
                            Text("쉬는시간 - 다음: \(viewModel.getDisplaySubject(for: currentClass))")
                                .bodyStyle()
                        case .lunchTime:
                            // 점심자습 시간이면 다른 표시 방식 사용
                            if currentClass.subject == "점심시간" {
                                Text("\(viewModel.getDisplaySubject(for: currentClass))")
                                    .bodyStyle()
                            } else {
                                Text("점심시간 - 다음: \(viewModel.getDisplaySubject(for: currentClass))")
                                    .bodyStyle()
                            }
                        case .preClass(_):
                            Text("수업 10분 전 - \(viewModel.getDisplaySubject(for: currentClass))")
                                .bodyStyle()
                        default:
                            // 아침자습이나 점심자습이면 수업 중이라는 표현을 사용하지 않음
                            if currentClass.subject == "아침자습" || currentClass.subject == "점심시간" {
                                Text("\(viewModel.getDisplaySubject(for: currentClass))")
                                    .bodyStyle()
                            } else {
                                Text("현재 \(viewModel.getDisplaySubject(for: currentClass)) 수업 중")
                                    .bodyStyle()
                            }
                        }
                        
                        let displayClassroom = viewModel.getDisplayClassroom(for: currentClass)
                        if !displayClassroom.isEmpty && !displayClassroom.contains("T") {
                            Text("교실: \(displayClassroom)")
                                .captionStyle()
                        }
                    }
                    
                    Spacer()
                }
                
                Button("🔗 \(connectionType.displayName) WiFi 연결하기") {
                    connectToWiFi(connectionType)
                }
                .primaryButtonStyle()
            }
            .appPadding()
            .cardStyle(backgroundColor: Color.appPrimary.withOpacity(0.05))
            .appPadding(.horizontal)
        }
    }
    
    /// 시간표 그리드 섹션
    private var scheduleGridSection: some View {
        GeometryReader { geometry in
            ScheduleGridView(
                scheduleData: scheduleService.currentScheduleData,
                grade: viewModel.displayGrade,
                classNumber: viewModel.displayClass,
                cellBackgroundColor: viewModel.cellBackgroundColor,
                geometry: geometry
            )
            .environmentObject(viewModel)
        }
        .appPadding([.horizontal, .bottom])
    }
    
    // MARK: - Private Methods
    
    /// 시간표 데이터 로드
    private func loadScheduleData() {
        Task {
            await scheduleService.loadSchedule(
                grade: viewModel.displayGrade,
                classNumber: viewModel.displayClass
            )
            viewModel.updateCurrentClassInfo(scheduleData: scheduleService.currentScheduleData)
        }
    }
    
    /// 주기적 업데이트 시작
    private func startPeriodicUpdate() {
        viewModel.startTimer()
        viewModel.updateCurrentClassInfo(scheduleData: scheduleService.currentScheduleData)
    }
    
    /// 알림 설정 업데이트
    private func updateNotificationSettings() {
        UserDefaults.standard.set(viewModel.displayGrade, forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        UserDefaults.standard.set(viewModel.displayClass, forKey: AppConstants.UserDefaultsKeys.defaultClass)
        
        Task {
            await scheduleService.updateNotifications(
                grade: viewModel.displayGrade,
                classNumber: viewModel.displayClass
            )
        }
        
        // 실제 설정 값 업데이트
        viewModel.actualGrade = viewModel.displayGrade
        viewModel.actualClass = viewModel.displayClass
    }
    
    /// WiFi 연결
    private func connectToWiFi(_ connectionType: WiFiConnectionType) {
        Task {
            let result: WiFiConnectionResult
            
            switch connectionType {
            case .regularClassroom(let grade, let classNumber):
                result = await wifiService.connectToClassroom(grade: grade, classNumber: classNumber)
            case .specialRoom(let room):
                result = await wifiService.connectToSpecialRoom(room)
            case .roomNumber(let grade, let classNumber):
                result = await wifiService.connectToRoomNumber(grade: grade, classNumber: classNumber)
            }
            
            await MainActor.run {
                wifiConnectionResult = result
                showWiFiConnectionAlert = true
            }
        }
    }
    
}