// AdvancedSettingsView.swift - 고급 설정 뷰
import SwiftUI

// MARK: - Import Result
enum ImportResult {
    case success
    case failure(String)
}

struct AdvancedSettingsView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: SettingsTabViewModel
    
    // MARK: - Environment Objects
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var notificationService: NotificationService
    
    // MARK: - State
    @State private var showResetAlert = false
    @State private var showExportAlert = false
    @State private var exportedData = ""
    @State private var showImportSheet = false
    @State private var importData = ""
    @State private var importResult: ImportResult?
    
    // MARK: - Body
    var body: some View {
        List {
            // 데이터 관리 섹션
            Section(NSLocalizedString(LocalizationKeys.dataManagement, comment: "")) {
                Button(NSLocalizedString(LocalizationKeys.resetAllSettings, comment: "")) {
                    showResetAlert = true
                }
                .foregroundColor(.errorColor)
                
                Button(NSLocalizedString(LocalizationKeys.exportSettings, comment: "")) {
                    exportSettings()
                }
                .foregroundColor(.appPrimary)
                
                Button(NSLocalizedString(LocalizationKeys.importSettings, comment: "")) {
                    showImportSheet = true
                }
                .foregroundColor(.appPrimary)
            }
            
            // 캐시 관리 섹션
            Section(NSLocalizedString(LocalizationKeys.cacheManagement, comment: "")) {
                Button(NSLocalizedString(LocalizationKeys.clearScheduleCache, comment: "")) {
                    clearScheduleCache()
                }
                .foregroundColor(.appPrimary)
                
                Button(NSLocalizedString(LocalizationKeys.removeAllNotifications, comment: "")) {
                    Task {
                        await notificationService.removeAllNotifications()
                    }
                }
                .foregroundColor(.warningColor)
            }
            
            // 디버그 정보 섹션
            Section(NSLocalizedString(LocalizationKeys.debugInfo, comment: "")) {
                HStack {
                    Text(NSLocalizedString(LocalizationKeys.currentScheduleData, comment: ""))
                    Spacer()
                    Text(scheduleService.currentScheduleData != nil ? NSLocalizedString(LocalizationKeys.exists, comment: "") : NSLocalizedString(LocalizationKeys.none, comment: ""))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(NSLocalizedString(LocalizationKeys.notificationPermission, comment: ""))
                    Spacer()
                    Text(notificationService.isAuthorized ? NSLocalizedString(LocalizationKeys.allowed, comment: "") : NSLocalizedString(LocalizationKeys.denied, comment: ""))
                        .foregroundColor(notificationService.isAuthorized ? .successColor : .errorColor)
                }
                
                HStack {
                    Text(NSLocalizedString(LocalizationKeys.liveActivityStatus, comment: ""))
                    Spacer()
                    if #available(iOS 18.0, *) {
                        Text(LiveActivityManager.shared.isActivityRunning ? NSLocalizedString(LocalizationKeys.running, comment: "") : NSLocalizedString(LocalizationKeys.stopped, comment: ""))
                            .foregroundColor(LiveActivityManager.shared.isActivityRunning ? .successColor : .secondary)
                    } else {
                        Text(NSLocalizedString(LocalizationKeys.ios18Required, comment: ""))
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(NSLocalizedString(LocalizationKeys.refreshNotificationPermission, comment: "")) {
                    notificationService.checkAuthorizationStatus()
                }
                .foregroundColor(.appPrimary)
            }
            
            // Live Activity 테스트 섹션
            Section(NSLocalizedString(LocalizationKeys.liveActivityTest, comment: "")) {
                Button(NSLocalizedString(LocalizationKeys.startLiveActivityTest, comment: "")) {
                    testStartLiveActivity()
                }
                .foregroundColor(.appPrimary)
                
                Button(NSLocalizedString(LocalizationKeys.stopLiveActivityTest, comment: "")) {
                    testStopLiveActivity()
                }
                .foregroundColor(.warningColor)
                
                Button(NSLocalizedString(LocalizationKeys.checkLiveActivityPermission, comment: "")) {
                    checkLiveActivityPermissions()
                }
                .foregroundColor(.appPrimary)
            }
        }
        .navigationTitle(NSLocalizedString(LocalizationKeys.advancedSettings, comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationAlert(
            isPresented: $showResetAlert,
            title: NSLocalizedString(LocalizationKeys.resetAllSettingsTitle, comment: ""),
            message: NSLocalizedString(LocalizationKeys.resetAllSettingsMessage, comment: ""),
            confirmTitle: NSLocalizedString(LocalizationKeys.reset, comment: ""),
            onConfirm: {
                resetAllSettings()
            }
        )
        .alert(NSLocalizedString(LocalizationKeys.settingsData, comment: ""), isPresented: $showExportAlert) {
            Button(NSLocalizedString(LocalizationKeys.copy, comment: "")) {
                UIPasteboard.general.string = exportedData
            }
            Button(NSLocalizedString(LocalizationKeys.ok, comment: ""), role: .cancel) { }
        } message: {
            Text(NSLocalizedString(LocalizationKeys.settingsDataGenerated, comment: ""))
        }
        .sheet(isPresented: $showImportSheet) {
            ImportDataView(
                importData: $importData,
                onImport: { data in
                    importSettings(data)
                },
                onCancel: {
                    showImportSheet = false
                    importData = ""
                }
            )
        }
        .alert(item: Binding<AlertItem?>(
            get: {
                if let result = importResult {
                    switch result {
                    case .success:
                        return AlertItem(id: "success", title: NSLocalizedString(LocalizationKeys.success, comment: ""), message: NSLocalizedString(LocalizationKeys.importSuccessMessage, comment: ""))
                    case .failure(let error):
                        return AlertItem(id: "failure", title: NSLocalizedString(LocalizationKeys.failed, comment: ""), message: String(format: NSLocalizedString(LocalizationKeys.importFailedMessage, comment: ""), error))
                    }
                }
                return nil
            },
            set: { _ in
                importResult = nil
            }
        )) { item in
            Alert(
                title: Text(item.title),
                message: Text(item.message),
                dismissButton: .default(Text(NSLocalizedString(LocalizationKeys.ok, comment: "")))
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// 설정 내보내기
    private func exportSettings() {
        let data = viewModel.exportAppData()
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            exportedData = String(data: jsonData, encoding: .utf8) ?? ""
            showExportAlert = true
        } catch {
            print("❌ 설정 내보내기 실패: \(error)")
        }
    }
    
    /// 설정 불러오기
    private func importSettings(_ jsonString: String) {
        do {
            guard let data = jsonString.data(using: .utf8) else {
                importResult = .failure("Invalid data format")
                return
            }
            
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dictionary = jsonObject as? [String: Any] else {
                importResult = .failure("Invalid JSON format")
                return
            }
            
            let success = viewModel.importAppData(dictionary)
            if success {
                importResult = .success
                showImportSheet = false
                importData = ""
            } else {
                importResult = .failure("Invalid settings data format or incompatible version")
            }
        } catch {
            importResult = .failure("JSON parsing failed: \(error.localizedDescription)")
        }
    }
    
    /// 모든 설정 초기화
    private func resetAllSettings() {
        // 뷰모델의 설정 초기화
        viewModel.resetAllSettings()
        
        // 시간표 서비스 초기화
        scheduleService.currentScheduleData = nil
        
        // 모든 알림 제거
        Task {
            await notificationService.removeAllNotifications()
        }
        
        // UserDefaults 초기화
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaultsKeys.initialSetupCompleted)
    }
    
    /// 시간표 캐시 삭제
    private func clearScheduleCache() {
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.scheduleDataStore)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.scheduleCompareStore)
        
        // 공유 UserDefaults도 정리
        SharedUserDefaults.shared.userDefaults.removeObject(forKey: AppConstants.UserDefaultsKeys.scheduleDataStore)
        
        // 현재 시간표 데이터 제거
        scheduleService.currentScheduleData = nil
        
        print("✅ 시간표 캐시가 삭제되었습니다")
    }
    
    // MARK: - Live Activity 테스트 메서드들
    
    /// Live Activity 시작 테스트
    private func testStartLiveActivity() {
        let grade = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        let classNumber = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
        
        print("🧪 Live Activity 수동 시작 테스트")
        print("   - 학년: \(grade), 반: \(classNumber)")
        
        if grade > 0 && classNumber > 0 {
            if #available(iOS 18.0, *) {
                LiveActivityManager.shared.startLiveActivity(grade: grade, classNumber: classNumber)
            } else {
                print("❌ iOS 18.0 이상이 필요합니다.")
            }
        } else {
            print("❌ 유효하지 않은 학년/반 정보. 설정에서 학년/반을 먼저 설정하세요.")
        }
    }
    
    /// Live Activity 중지 테스트
    private func testStopLiveActivity() {
        print("🧪 Live Activity 수동 중지 테스트")
        if #available(iOS 18.0, *) {
            LiveActivityManager.shared.stopLiveActivity()
        } else {
            print("❌ iOS 18.0 이상이 필요합니다.")
        }
    }
    
    /// Live Activity 권한 확인
    private func checkLiveActivityPermissions() {
        print("🧪 Live Activity 권한 상태 확인")
        if #available(iOS 18.0, *) {
            print("   - 현재 실행 상태: \(LiveActivityManager.shared.isActivityRunning)")
        } else {
            print("   - iOS 18.0 이상이 필요합니다.")
        }
        
        // LiveActivityManager의 메서드를 통해 확인
        let grade = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        let classNumber = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
        
        if grade > 0 && classNumber > 0 {
            // 권한 확인만 하고 실제로 시작하지는 않음
            print("   - 설정된 학년/반: \(grade)학년 \(classNumber)반")
        } else {
            print("   - 경고: 학년/반이 설정되지 않음")
        }
    }
}

// MARK: - Alert Item
struct AlertItem: Identifiable {
    let id: String
    let title: String
    let message: String
}

// MARK: - Import Data View
struct ImportDataView: View {
    @Binding var importData: String
    let onImport: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString(LocalizationKeys.importSettingsData, comment: ""))
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text(NSLocalizedString(LocalizationKeys.importInstructions, comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString(LocalizationKeys.jsonData, comment: ""))
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $importData)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .frame(minHeight: 200)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString(LocalizationKeys.cancel, comment: "")) {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString(LocalizationKeys.import, comment: "")) {
                        onImport(importData)
                    }
                    .disabled(importData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - 미리보기
struct AdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdvancedSettingsView(viewModel: SettingsTabViewModel())
                .environmentObject(ScheduleService.shared)
                .environmentObject(NotificationService.shared)
        }
        .previewDisplayName("고급 설정")
    }
}