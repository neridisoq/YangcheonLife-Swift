import SwiftUI

struct ContentView: View {
    @State private var showInitialSetup = !UserDefaults.standard.bool(forKey: "initialSetupCompleted")
    @ObservedObject private var updateService = AppUpdateService.shared
    
    // 업데이트 안내 표시 여부를 제어하는 상태 변수 추가
    @State private var showUpdateAnnouncement = false
    
    var body: some View {
        ZStack {
            Group {
                if updateService.updateRequired {
                    // 새 버전이 사용 가능한 경우 업데이트 필요 뷰 표시
                    UpdateRequiredView()
                } else if showInitialSetup {
                    InitialSetupView(showInitialSetup: $showInitialSetup)
                } else {
                    MainView() // 메인 화면 뷰
                }
            }
            
            // 업데이트 안내 조건부 표시
            if showUpdateAnnouncement {
                UpdateAnnouncementView(showUpdateAnnouncement: $showUpdateAnnouncement)
                    .transition(.opacity)
                    .zIndex(100) // 다른 모든 요소 위에 표시되도록 함
            }
        }
        .onAppear {
            // 앱이 나타날 때 업데이트 확인
            updateService.checkForUpdates()
            
            // 업데이트 안내를 표시해야 하는지 확인
            checkForVersionAnnouncement()
        }
    }
    
    // 업데이트 안내를 표시해야 하는지 확인하는 메서드
    private func checkForVersionAnnouncement() {
        // 현재 버전과 사용자가 확인한 최신 버전 가져오기
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let lastSeenVersion = UserDefaults.standard.string(forKey: "lastSeenUpdateVersion") ?? ""
        
        // 현재 버전이 "3.2"이고, 마지막으로 확인한 버전이 "3.1"이 아닌 경우에만 표시
        if currentVersion == "3.2" && lastSeenVersion != "3.1" && lastSeenVersion != "3.2" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showUpdateAnnouncement = true
                }
            }
        }
    }
}

struct MainView: View {
    var body: some View {
        TabView {
            TimeTableTab()
                .tabItem {
                    Label(NSLocalizedString("TimeTable", comment: ""), systemImage: "calendar")
                }
            LunchTab()
                .tabItem {
                    Label(NSLocalizedString("Meal", comment: ""), systemImage: "fork.knife")
                }
            SettingsTab()
                .tabItem {
                    Label(NSLocalizedString("Settings", comment: ""), systemImage: "gear")
                }
        }
    }
}
