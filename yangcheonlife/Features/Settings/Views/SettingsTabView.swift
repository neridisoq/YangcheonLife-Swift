// SettingsTabView.swift - 설정 탭 뷰 (새 UI + 원래 기능)
import SwiftUI
import UserNotifications
import WidgetKit

struct SettingsTabView: View {
    
    // MARK: - ViewModel
    @StateObject private var viewModel = SettingsTabViewModel()
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    
    @State private var showConfirmationAlert = false
    @State private var confirmationMessage = ""
    @State private var pendingAction: (() -> Void)?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                // Live Activity 제어 섹션
                liveActivitySection
                
                // 기본 설정 섹션
                basicSettingsSection
                
                // 알림 설정 섹션  
                notificationSettingsSection
                
                // 앱 정보 섹션
                appInfoSection
                
                // 지원 섹션
                supportSection
            }
            .navigationTitle(NSLocalizedString(LocalizationKeys.settings, comment: ""))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadSettings()
                if viewModel.notificationsEnabled {
                    updateLocalScheduleAndNotifications()
                }
            }
            .confirmationAlert(
                isPresented: $showConfirmationAlert,
                title: "확인",
                message: confirmationMessage,
                onConfirm: {
                    pendingAction?()
                    pendingAction = nil
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - View Sections
    
    /// Live Activity 제어 섹션
    private var liveActivitySection: some View {
        Section("라이브 액티비티") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dynamic Island 표시")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("현재 수업, 다음 수업, 남은 시간을 Dynamic Island와 잠금 화면에서 확인")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if liveActivityManager.isActivityRunning {
                    Text("실행 중")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack {
                if !liveActivityManager.isActivityRunning {
                    Button("시작하기") {
                        startLiveActivity()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(10)
                } else {
                    Button("중지하기") {
                        stopLiveActivity()
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
    
    /// 기본 설정 섹션
    private var basicSettingsSection: some View {
        Section("기본 설정") {
            // 학년/반 설정
            NavigationLink("학년 및 반 설정") {
                ClassGradeSettingsView(
                    defaultGrade: $viewModel.defaultGrade,
                    defaultClass: $viewModel.defaultClass,
                    notificationsEnabled: $viewModel.notificationsEnabled
                )
            }
            
            // 과목 선택
            NavigationLink("탐구/기초 과목 선택") {
                SubjectSelectionView()
            }
            
            // WiFi 연결
            NavigationLink("학교 WiFi 연결") {
                WiFiConnectionView()
            }
            
            // WiFi 제안 기능
            Toggle("WiFi 제안 기능", isOn: $viewModel.wifiSuggestionEnabled)
                .onChange(of: viewModel.wifiSuggestionEnabled) { isEnabled in
                    viewModel.saveWifiSuggestionEnabled(isEnabled)
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
                    
                    if viewModel.notificationsEnabled && viewModel.physicalEducationAlertEnabled {
                        Task {
                            await NotificationService.shared.schedulePhysicalEducationAlerts()
                        }
                    }
                }
            }
            
            // 알림 테스트 버튼
            if viewModel.notificationsEnabled {
                Button("알림 테스트") {
                    Task {
                        await NotificationService.shared.sendTestNotification()
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
            
            HStack {
                Text("개발")
                Spacer()
                Text("30526 진우현")
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
            }
        }
    }
    
    // MARK: - Private Methods (원래 기능들)
    
    
    /// 수업 알림 토글 처리
    private func handleNotificationToggle(_ isEnabled: Bool) {
        if isEnabled {
            // 알림 권한 요청
            Task {
                let granted = await NotificationService.shared.requestAuthorization()
                
                await MainActor.run {
                    if granted {
                        viewModel.saveNotificationsEnabled(true)
                        updateLocalScheduleAndNotifications()
                    } else {
                        viewModel.saveNotificationsEnabled(false)
                        showPermissionAlert()
                    }
                }
            }
        } else {
            // 알림 비활성화
            confirmationMessage = "모든 수업 알림이 비활성화됩니다. 계속하시겠습니까?"
            pendingAction = {
                viewModel.saveNotificationsEnabled(false)
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
            showConfirmationAlert = true
        }
    }
    
    /// 체육 수업 알림 토글 처리
    private func handlePhysicalEducationAlertToggle(_ isEnabled: Bool) {
        viewModel.savePhysicalEducationAlertEnabled(isEnabled)
        
        if isEnabled && viewModel.notificationsEnabled {
            Task {
                await NotificationService.shared.schedulePhysicalEducationAlerts()
            }
        } else {
            Task {
                await NotificationService.shared.removePhysicalEducationAlerts()
            }
        }
    }
    
    
    /// 시간표 알림 업데이트 (원래 방식)
    private func updateLocalScheduleAndNotifications() {
        if viewModel.notificationsEnabled {
            Task {
                await ScheduleService.shared.updateNotifications(grade: viewModel.defaultGrade, classNumber: viewModel.defaultClass)
            }
            
            if viewModel.physicalEducationAlertEnabled {
                Task {
                    await NotificationService.shared.schedulePhysicalEducationAlerts()
                }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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
    
    // MARK: - Live Activity Methods
    
    /// Live Activity 시작
    private func startLiveActivity() {
        liveActivityManager.startLiveActivity(
            grade: viewModel.defaultGrade,
            classNumber: viewModel.defaultClass
        )
    }
    
    /// Live Activity 중지
    private func stopLiveActivity() {
        liveActivityManager.stopLiveActivity()
    }
}

// MARK: - 미리보기
struct SettingsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTabView()
            .previewDisplayName("설정 탭")
    }
}
