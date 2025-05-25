import SwiftUI
import UserNotifications
import NetworkExtension
import WidgetKit

struct SettingsTabView: View {
    @State private var defaultGrade: Int = UserDefaults.standard.integer(forKey: "defaultGrade")
    @State private var defaultClass: Int = UserDefaults.standard.integer(forKey: "defaultClass")
    @State private var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var physicalEducationAlertEnabled: Bool = UserDefaults.standard.bool(forKey: "physicalEducationAlertEnabled")
    @State private var physicalEducationAlertTime: Date = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let timeString = UserDefaults.standard.string(forKey: "physicalEducationAlertTime"),
           let date = formatter.date(from: timeString) {
            return date
        } else {
            let calendar = Calendar.current
            let components = DateComponents(hour: 7, minute: 0)
            return calendar.date(from: components) ?? Date()
        }
    }()
    @State private var cellBackgroundColor: Color = {
        if let data = UserDefaults.standard.data(forKey: "cellBackgroundColor"),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            return Color(uiColor)
        }
        return Color.yellow.opacity(0.3)
    }()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(NSLocalizedString("Settings", comment: ""))) {
                    NavigationLink(NSLocalizedString("ClassSettings", comment: ""), destination: ClassAndGradeView(defaultGrade: $defaultGrade, defaultClass: $defaultClass, notificationsEnabled: $notificationsEnabled))
                    
                    NavigationLink("탐구/기초 과목 선택", destination: SubjectSelectionView())
                    
                    NavigationLink("학교 Wi-Fi 연결", destination: WiFiConnectionView())
                    
                    ColorPicker(NSLocalizedString("ColorPicker", comment: ""), selection: $cellBackgroundColor)
                        .onChange(of: cellBackgroundColor) { newColor in
                            saveCellBackgroundColor(newColor)
                            updateSharedUserDefaults()
                        }
                }
                
                Section(header: Text(NSLocalizedString("Alert", comment: ""))) {
                    Toggle(NSLocalizedString("Alert Settings", comment: ""), isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { value in
                            UserDefaults.standard.set(value, forKey: "notificationsEnabled")
                            if value {
                                updateLocalScheduleAndNotifications()
                            } else {
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                            updateSharedUserDefaults()
                        }
                    
                    Toggle("체육 수업 알림 활성화", isOn: $physicalEducationAlertEnabled)
                        .onChange(of: physicalEducationAlertEnabled) { value in
                            UserDefaults.standard.set(value, forKey: "physicalEducationAlertEnabled")
                            if value && notificationsEnabled {
                                Task {
                                    await NotificationService.shared.schedulePhysicalEducationAlerts()
                                }
                            } else {
                                Task {
                                    await NotificationService.shared.removePhysicalEducationAlerts()
                                }
                            }
                            updateSharedUserDefaults()
                        }
                    
                    if physicalEducationAlertEnabled {
                        DatePicker("체육 알림 시간", selection: $physicalEducationAlertTime, displayedComponents: .hourAndMinute)
                            .onChange(of: physicalEducationAlertTime) { newValue in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                let timeString = formatter.string(from: newValue)
                                UserDefaults.standard.set(timeString, forKey: "physicalEducationAlertTime")
                                
                                if physicalEducationAlertEnabled && notificationsEnabled {
                                    Task {
                                        await NotificationService.shared.schedulePhysicalEducationAlerts()
                                    }
                                }
                                updateSharedUserDefaults()
                            }
                    }
                }
                
                Section(header: Text(NSLocalizedString("Link", comment: ""))) {
                    Link(NSLocalizedString("Privacy Policy", comment: ""), destination: URL(string: "https://yangcheon.sen.hs.kr/dggb/module/policy/selectPolicyDetail.do?policyTypeCode=PLC002&menuNo=75574")!)
                    Link(NSLocalizedString("Goto School Web", comment: ""), destination: URL(string: "https://yangcheon.sen.hs.kr")!)
                }
                
                Section(header: Text(NSLocalizedString("Support", comment: ""))) {
                    Button(action: {
                        sendEmail()
                    }) {
                        HStack {
                            Text(NSLocalizedString("Supportto", comment: ""))
                            Spacer()
                            Image(systemName: "envelope")
                        }
                    }
                    Link(NSLocalizedString("개발자 인스타그램", comment: ""), destination: URL(string: "https://instagram.com/neridisoq_")!)
                }
            }
            .navigationBarTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadSettings()
            if notificationsEnabled {
                updateLocalScheduleAndNotifications()
            }
        }
        .onDisappear {
            updateSharedUserDefaults()
        }
    }
    
    // MARK: - View Sections
    
    /// 기본 설정 섹션
    private var basicSettingsSection: some View {
        Section("기본 설정") {
            // 학년/반 설정
            NavigationLink("학년 및 반 설정") {
                ClassGradeSettingsView(viewModel: viewModel)
                    .environmentObject(scheduleService)
                    .environmentObject(notificationService)
            }
            
            // 과목 선택
            NavigationLink("탐구/기초 과목 선택") {
                SubjectSelectionView()
            }
            
            // WiFi 연결
            NavigationLink("학교 WiFi 연결") {
                WiFiConnectionView()
            }
            
            // 시간표 셀 배경색
            ColorPicker("시간표 셀 색상", selection: $viewModel.cellBackgroundColor)
                .onChange(of: viewModel.cellBackgroundColor) { newColor in
                    viewModel.saveCellBackgroundColor(newColor)
                }
        }
    }
    
    /// 알림 설정 섹션
    private var notificationSettingsSection: some View {
        Section("알림 설정") {
            // 수업 알림 토글
            Toggle("수업 알림", isOn: $viewModel.notificationsEnabled)
                .onChange(of: viewModel.notificationsEnabled) { isEnabled in
                    handleNotificationToggle(isEnabled)
                }
            
            // 체육 수업 알림
            Toggle("체육 수업 알림", isOn: $viewModel.physicalEducationAlertEnabled)
                .onChange(of: viewModel.physicalEducationAlertEnabled) { isEnabled in
                    handlePhysicalEducationAlertToggle(isEnabled)
                }
            
            // 체육 알림 시간 설정
            if viewModel.physicalEducationAlertEnabled {
                DatePicker(
                    "체육 알림 시간",
                    selection: $viewModel.physicalEducationAlertTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: viewModel.physicalEducationAlertTime) { newTime in
                    viewModel.savePhysicalEducationAlertTime(newTime)
                    
                    if viewModel.notificationsEnabled {
                        Task {
                            await notificationService.schedulePhysicalEducationAlerts()
                        }
                    }
                }
            }
            
            // 알림 테스트 버튼
            if viewModel.notificationsEnabled {
                Button("알림 테스트") {
                    Task {
                        await notificationService.sendTestNotification()
                    }
                }
                .foregroundColor(.appPrimary)
            }
        }
    }
    
    /// 앱 정보 섹션
    private var appInfoSection: some View {
        Section("앱 정보") {
            HStack {
                Text("버전")
                Spacer()
                Text(AppConstants.App.version)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("앱 이름")
                Spacer()
                Text(AppConstants.App.name)
                    .foregroundColor(.secondary)
            }
            
            Link("개인정보처리방침", destination: URL(string: AppConstants.ExternalLinks.privacyPolicy)!)
            Link("학교 홈페이지", destination: URL(string: AppConstants.ExternalLinks.schoolWebsite)!)
        }
    }
    
    /// 지원 섹션
    private var supportSection: some View {
        Section("지원") {
            Button(action: sendEmail) {
                HStack {
                    Text("개발자에게 이메일 보내기")
                    Spacer()
                    Image(systemName: "envelope")
                        .foregroundColor(.secondary)
                }
            }
            
            Link("개발자 인스타그램", destination: URL(string: AppConstants.ExternalLinks.developerInstagram)!)
            
            // 고급 설정
            NavigationLink("고급 설정") {
                AdvancedSettingsView(viewModel: viewModel)
                    .environmentObject(scheduleService)
                    .environmentObject(notificationService)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 수업 알림 토글 처리
    private func handleNotificationToggle(_ isEnabled: Bool) {
        if isEnabled {
            // 알림 권한 요청
            Task {
                let granted = await notificationService.requestAuthorization()
                
                await MainActor.run {
                    if granted {
                        viewModel.saveNotificationsEnabled(true)
                        updateScheduleNotifications()
                    } else {
                        viewModel.notificationsEnabled = false
                        showPermissionAlert()
                    }
                }
            }
        } else {
            // 알림 비활성화
            confirmationMessage = "모든 수업 알림이 비활성화됩니다. 계속하시겠습니까?"
            pendingAction = {
                viewModel.saveNotificationsEnabled(false)
                Task {
                    await notificationService.removeAllNotifications()
                }
            }
            showConfirmationAlert = true
        }
    }
    
    /// 체육 수업 알림 토글 처리
    private func handlePhysicalEducationAlertToggle(_ isEnabled: Bool) {
        viewModel.savePhysicalEducationAlertEnabled(isEnabled)
        
        if isEnabled && viewModel.notificationsEnabled {
            Task {
                await notificationService.schedulePhysicalEducationAlerts()
            }
        } else {
            Task {
                await notificationService.removePhysicalEducationAlerts()
            }
        }
    }
    
    /// 시간표 알림 업데이트
    private func updateScheduleNotifications() {
        Task {
            await scheduleService.updateNotifications(
                grade: viewModel.defaultGrade,
                classNumber: viewModel.defaultClass
            )
            
            if viewModel.physicalEducationAlertEnabled {
                await notificationService.schedulePhysicalEducationAlerts()
            }
        }
    }
    
    /// 권한 없음 알림 표시
    private func showPermissionAlert() {
        confirmationMessage = "알림 권한이 필요합니다. 설정에서 알림을 허용해주세요."
        pendingAction = {
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }
        showConfirmationAlert = true
    }
    
    /// 이메일 보내기
    private func sendEmail() {
        if let url = URL(string: "mailto:\(AppConstants.ExternalLinks.supportEmail)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - 미리보기
struct SettingsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTabView()
            .environmentObject(ScheduleService.shared)
            .environmentObject(NotificationService.shared)
            .previewDisplayName("설정 탭")
    }
}