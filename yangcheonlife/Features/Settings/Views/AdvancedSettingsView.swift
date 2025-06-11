// AdvancedSettingsView.swift - 고급 설정 뷰
import SwiftUI

struct AdvancedSettingsView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: SettingsTabViewModel
    
    // MARK: - Environment Objects
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var liveActivityManager: LiveActivityManager
    
    // MARK: - State
    @State private var showResetAlert = false
    @State private var showExportAlert = false
    @State private var exportedData = ""
    
    // MARK: - Body
    var body: some View {
        List {
            // 데이터 관리 섹션
            Section("데이터 관리") {
                Button("모든 설정 초기화") {
                    showResetAlert = true
                }
                .foregroundColor(.errorColor)
                
                Button("설정 데이터 내보내기") {
                    exportSettings()
                }
                .foregroundColor(.appPrimary)
            }
            
            // 캐시 관리 섹션
            Section("캐시 관리") {
                Button("시간표 캐시 삭제") {
                    clearScheduleCache()
                }
                .foregroundColor(.appPrimary)
                
                Button("모든 알림 제거") {
                    Task {
                        await notificationService.removeAllNotifications()
                    }
                }
                .foregroundColor(.warningColor)
            }
            
            // 디버그 정보 섹션
            Section("디버그 정보") {
                HStack {
                    Text("현재 시간표 데이터")
                    Spacer()
                    Text(scheduleService.currentScheduleData != nil ? "있음" : "없음")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("알림 권한")
                    Spacer()
                    Text(notificationService.isAuthorized ? "허용" : "거부")
                        .foregroundColor(notificationService.isAuthorized ? .successColor : .errorColor)
                }
                
                HStack {
                    Text("Live Activity 상태")
                    Spacer()
                    Text(liveActivityManager.isActivityRunning ? "실행 중" : "중지됨")
                        .foregroundColor(liveActivityManager.isActivityRunning ? .successColor : .secondary)
                }
                
                Button("알림 권한 상태 새로고침") {
                    notificationService.checkAuthorizationStatus()
                }
                .foregroundColor(.appPrimary)
            }
            
            // Live Activity 테스트 섹션
            Section("Live Activity 테스트") {
                Button("Live Activity 시작 테스트") {
                    testStartLiveActivity()
                }
                .foregroundColor(.appPrimary)
                
                Button("Live Activity 중지 테스트") {
                    testStopLiveActivity()
                }
                .foregroundColor(.warningColor)
                
                Button("Live Activity 권한 확인") {
                    checkLiveActivityPermissions()
                }
                .foregroundColor(.appPrimary)
            }
        }
        .navigationTitle("고급 설정")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationAlert(
            isPresented: $showResetAlert,
            title: "모든 설정 초기화",
            message: "모든 설정이 기본값으로 되돌아갑니다. 이 작업은 되돌릴 수 없습니다.",
            confirmTitle: "초기화",
            onConfirm: {
                resetAllSettings()
            }
        )
        .alert("설정 데이터", isPresented: $showExportAlert) {
            Button("복사하기") {
                UIPasteboard.general.string = exportedData
            }
            Button("확인", role: .cancel) { }
        } message: {
            Text("설정 데이터가 생성되었습니다. 복사하여 백업하세요.")
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
            liveActivityManager.startLiveActivity(grade: grade, classNumber: classNumber)
        } else {
            print("❌ 유효하지 않은 학년/반 정보. 설정에서 학년/반을 먼저 설정하세요.")
        }
    }
    
    /// Live Activity 중지 테스트
    private func testStopLiveActivity() {
        print("🧪 Live Activity 수동 중지 테스트")
        liveActivityManager.stopLiveActivity()
    }
    
    /// Live Activity 권한 확인
    private func checkLiveActivityPermissions() {
        print("🧪 Live Activity 권한 상태 확인")
        print("   - 현재 실행 상태: \(liveActivityManager.isActivityRunning)")
        
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