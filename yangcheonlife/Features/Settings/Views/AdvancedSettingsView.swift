// AdvancedSettingsView.swift - 고급 설정 뷰
import SwiftUI

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
                
                Button("알림 권한 상태 새로고침") {
                    notificationService.checkAuthorizationStatus()
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