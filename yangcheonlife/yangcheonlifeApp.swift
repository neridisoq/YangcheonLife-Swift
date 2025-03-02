//yangcheonlifeApp.swift
import SwiftUI
import Firebase

@main
struct yangcheonlifeApp: App {
    // Integrate the AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Any additional setup if needed
                }
        }
    }
}
