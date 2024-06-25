import SwiftUI

struct ContentView: View {
    @State private var showInitialSetup = !UserDefaults.standard.bool(forKey: "initialSetupCompleted")
    
    var body: some View {
        if showInitialSetup {
            InitialSetupView(showInitialSetup: $showInitialSetup)
        } else {
            MainView() // 메인 화면 뷰
        }
    }
}

struct MainView: View {
    var body: some View {
        TabView {
            TimeTableTab()
                .tabItem {
                    Label("시간표", systemImage: "calendar")
                }
            LunchTab()
                .tabItem {
                    Label("급식", systemImage: "fork.knife")
                }
            SettingsTab()
                .tabItem {
                    Label("설정", systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
