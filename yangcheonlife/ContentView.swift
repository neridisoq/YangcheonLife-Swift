// ContentView.swift - 메인 컨텐츠 뷰
import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    @State private var showInitialSetup = !UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.initialSetupCompleted)
    @State private var showUpdateAnnouncement = false
    @ObservedObject private var updateService = AppUpdateService.shared
    
    // MARK: - Environment Objects
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var wifiService: WiFiService
    @EnvironmentObject var notificationService: NotificationService
    
    // MARK: - Body
    var body: some View {
        ZStack {
            mainContent
            
            // 업데이트 안내 오버레이
            updateAnnouncementOverlay
        }
        .onAppear {
            setupContentView()
        }
    }
    
    // MARK: - Computed Properties
    
    /// 메인 컨텐츠
    @ViewBuilder
    private var mainContent: some View {
        if updateService.updateRequired {
            UpdateRequiredView()
        } else if showInitialSetup {
            InitialSetupView(showInitialSetup: $showInitialSetup)
        } else {
            MainTabView()
        }
    }
    
    /// 업데이트 안내 오버레이
    @ViewBuilder
    private var updateAnnouncementOverlay: some View {
        if showUpdateAnnouncement {
            UpdateAnnouncementView(showUpdateAnnouncement: $showUpdateAnnouncement)
                .transition(.opacity)
                .zIndex(100)
        }
    }
    
    // MARK: - Private Methods
    
    /// ContentView 초기 설정
    private func setupContentView() {
        // 업데이트 확인
        updateService.checkForUpdates()
        
        // 버전 안내 확인
        checkForVersionAnnouncement()
    }
    
    /// 버전 업데이트 안내 확인
    private func checkForVersionAnnouncement() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let lastSeenVersion = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.lastSeenUpdateVersion) ?? ""
        
        // 버전 4.0으로 업데이트
        if currentVersion == AppConstants.App.version && lastSeenVersion != AppConstants.App.version {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showUpdateAnnouncement = true
                }
            }
        }
    }
}

// MARK: - 메인 탭 뷰
struct MainTabView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var wifiService: WiFiService
    @EnvironmentObject var notificationService: NotificationService
    
    // MARK: - Body
    var body: some View {
        TabView {
            // 시간표 탭
            ScheduleTabView()
                .tabItem {
                    Label(NSLocalizedString(LocalizationKeys.timeTable, comment: ""), systemImage: "calendar")
                }
                .environmentObject(scheduleService)
                .environmentObject(wifiService)
            
            // 급식 탭
            MealTabView()
                .tabItem {
                    Label(NSLocalizedString(LocalizationKeys.meal, comment: ""), systemImage: "fork.knife")
                }
            
            // 설정 탭
            SettingsTabView()
                .tabItem {
                    Label(NSLocalizedString(LocalizationKeys.settings, comment: ""), systemImage: "gear")
                }
        }
        .accentColor(.appPrimary)
    }
}
