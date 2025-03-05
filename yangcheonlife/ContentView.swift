//ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var showInitialSetup = !UserDefaults.standard.bool(forKey: "initialSetupCompleted")
    @ObservedObject private var updateService = AppUpdateService.shared
    
    var body: some View {
        Group {
            if updateService.updateRequired {
                // Show update required view when a new version is available
                UpdateRequiredView()
            } else if showInitialSetup {
                InitialSetupView(showInitialSetup: $showInitialSetup)
            } else {
                MainView() // 메인 화면 뷰
            }
        }
        .onAppear {
            // Check for app updates when the view appears
            updateService.checkForUpdates()
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
