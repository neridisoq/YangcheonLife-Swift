// SettingsTabView.swift - 설정 탭 뷰 (새 UI + 원래 기능)
import SwiftUI
import UserNotifications
import WidgetKit

struct SettingsTabView: View {
    
    // MARK: - ViewModel
    @StateObject private var viewModel = SettingsTabViewModel()
    
    @State private var showConfirmationAlert = false
    @State private var confirmationMessage = ""
    @State private var pendingAction: (() -> Void)?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                // Live Activity 제어 섹션
                
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
                title: NSLocalizedString(LocalizationKeys.confirm, comment: ""),
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
    @ViewBuilder
    private var liveActivitySection: some View {
        if #available(iOS 18.0, *) {
            Section(NSLocalizedString(LocalizationKeys.liveActivity, comment: "")) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(NSLocalizedString(LocalizationKeys.liveActivityDisplay, comment: ""))
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if #available(iOS 18.0, *), viewModel.isLiveActivityRunning {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text(NSLocalizedString(LocalizationKeys.running, comment: ""))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                    
                    Text(NSLocalizedString(LocalizationKeys.liveActivityDescription, comment: ""))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if #available(iOS 18.0, *) {
                    if !viewModel.isLiveActivityRunning {
                        Button(action: {
                            startLiveActivity()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                Text(NSLocalizedString(LocalizationKeys.start, comment: ""))
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            stopLiveActivity()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title3)
                                Text(NSLocalizedString(LocalizationKeys.stop, comment: ""))
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(10)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text(NSLocalizedString(LocalizationKeys.iosVersionRequired, comment: ""))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        }
    }
    
    /// 기본 설정 섹션
    private var basicSettingsSection: some View {
        Section(NSLocalizedString(LocalizationKeys.basicSettings, comment: "")) {
            // 학년/반 설정
            NavigationLink(NSLocalizedString(LocalizationKeys.gradeClassSettings, comment: "")) {
                ClassGradeSettingsView(
                    defaultGrade: $viewModel.defaultGrade,
                    defaultClass: $viewModel.defaultClass,
                    notificationsEnabled: $viewModel.notificationsEnabled
                )
            }
            
            // 과목 선택
            NavigationLink(NSLocalizedString(LocalizationKeys.subjectSelection, comment: "")) {
                SubjectSelectionView()
            }
            
            // WiFi 연결
            NavigationLink(NSLocalizedString(LocalizationKeys.wifiConnection, comment: "")) {
                WiFiConnectionView()
            }
            
            // WiFi 제안 기능
            Toggle(NSLocalizedString(LocalizationKeys.wifiSuggestion, comment: ""), isOn: $viewModel.wifiSuggestionEnabled)
                .onChange(of: viewModel.wifiSuggestionEnabled) { isEnabled in
                    viewModel.saveWifiSuggestionEnabled(isEnabled)
                }
            
            // 시간표 셀 배경색
            ColorPicker(NSLocalizedString(LocalizationKeys.scheduleCellColor, comment: ""), selection: $viewModel.cellBackgroundColor)
                .onChange(of: viewModel.cellBackgroundColor) { newColor in
                    viewModel.saveCellBackgroundColor(newColor)
                }
        }
    }
    
    /// 알림 설정 섹션
    private var notificationSettingsSection: some View {
        Section(NSLocalizedString(LocalizationKeys.notificationSettings, comment: "")) {
            // 수업 알림 토글
            Toggle(NSLocalizedString(LocalizationKeys.classNotification, comment: ""), isOn: $viewModel.notificationsEnabled)
                .onChange(of: viewModel.notificationsEnabled) { isEnabled in
                    handleNotificationToggle(isEnabled)
                }
            
            // 체육 수업 알림
            Toggle(NSLocalizedString(LocalizationKeys.peNotification, comment: ""), isOn: $viewModel.physicalEducationAlertEnabled)
                .onChange(of: viewModel.physicalEducationAlertEnabled) { isEnabled in
                    handlePhysicalEducationAlertToggle(isEnabled)
                }
            
            // 체육 알림 시간 설정
            if viewModel.physicalEducationAlertEnabled {
                DatePicker(
                    NSLocalizedString(LocalizationKeys.peNotificationTime, comment: ""),
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
                Button(NSLocalizedString(LocalizationKeys.testNotification, comment: "")) {
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
        Section(NSLocalizedString(LocalizationKeys.appInfo, comment: "")) {
            HStack {
                Text(NSLocalizedString(LocalizationKeys.version, comment: ""))
                Spacer()
                Text(AppConstants.App.version)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(NSLocalizedString(LocalizationKeys.appName, comment: ""))
                Spacer()
                Text(AppConstants.App.name)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(NSLocalizedString(LocalizationKeys.developer, comment: ""))
                Spacer()
                Text(NSLocalizedString(LocalizationKeys.developerName, comment: ""))
                    .foregroundColor(.secondary)
            }
            
            Link(NSLocalizedString(LocalizationKeys.privacyPolicy, comment: ""), destination: URL(string: AppConstants.ExternalLinks.privacyPolicy)!)
            Link(NSLocalizedString(LocalizationKeys.schoolWebsite, comment: ""), destination: URL(string: AppConstants.ExternalLinks.schoolWebsite)!)
        }
    }
    
    /// 지원 섹션
    private var supportSection: some View {
        Section(NSLocalizedString(LocalizationKeys.support, comment: "")) {
            Button(action: sendEmail) {
                HStack {
                    Text(NSLocalizedString(LocalizationKeys.sendEmailToDeveloper, comment: ""))
                    Spacer()
                    Image(systemName: "envelope")
                        .foregroundColor(.secondary)
                }
            }
            
            Link(NSLocalizedString(LocalizationKeys.developerInstagram, comment: ""), destination: URL(string: AppConstants.ExternalLinks.developerInstagram)!)
            
            // 고급 설정
            NavigationLink(NSLocalizedString(LocalizationKeys.advancedSettings, comment: "")) {
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
            confirmationMessage = NSLocalizedString(LocalizationKeys.allNotificationsDisabled, comment: "")
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
        confirmationMessage = NSLocalizedString(LocalizationKeys.notificationPermissionRequired, comment: "")
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
    @available(iOS 18.0, *)
    private func startLiveActivity() {
        LiveActivityManager.shared.startLiveActivity(
            grade: viewModel.defaultGrade,
            classNumber: viewModel.defaultClass
        )
        // UI 상태 즉시 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.viewModel.objectWillChange.send()
        }
    }
    
    /// Live Activity 중지
    @available(iOS 18.0, *)
    private func stopLiveActivity() {
        LiveActivityManager.shared.stopLiveActivity()
        // UI 상태 즉시 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.viewModel.objectWillChange.send()
        }
    }
    
    /// Live Activity 업데이트
    @available(iOS 18.0, *)
    private func updateLiveActivity() {
        LiveActivityManager.shared.updateLiveActivity()
    }
}

// MARK: - 미리보기
struct SettingsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTabView()
            .previewDisplayName("설정 탭")
    }
}
