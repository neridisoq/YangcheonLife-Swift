import SwiftUI
import UserNotifications

struct InitialSetupView: View {
    @Binding var showInitialSetup: Bool
    @State private var defaultGrade: Int = 1
    @State private var defaultClass: Int = 1
    @State private var notificationsEnabled: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("ClassSettings", comment: ""))) {
                    Picker(NSLocalizedString("Grade", comment: ""), selection: $defaultGrade) {
                        ForEach(1..<4) { grade in
                            Text(String(format: NSLocalizedString("GradeP", comment: ""), grade)).tag(grade)
                        }
                    }
                    
                    Picker(NSLocalizedString("Class", comment: ""), selection: $defaultClass) {
                        ForEach(1..<12) { classNumber in
                            Text(String(format: NSLocalizedString("ClassP", comment: ""), classNumber)).tag(classNumber)
                        }
                    }
                }
                
                Section(header: Text(NSLocalizedString("Alert", comment: ""))) {
                    Toggle(NSLocalizedString("Alert Settings", comment: ""), isOn: $notificationsEnabled)
                }
                
                Section(header: Text("안내")) {
                    Text("탐구/기초 과목 선택은 설정 메뉴에서 할 수 있습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button(action: saveSettings) {
                    Text(NSLocalizedString("Done", comment: ""))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
            }
            .navigationBarTitle(NSLocalizedString("Initial Setup", comment: ""))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Permission granted: \(granted)")
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(defaultGrade, forKey: "defaultGrade")
        UserDefaults.standard.set(defaultClass, forKey: "defaultClass")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(true, forKey: "initialSetupCompleted")
        
        // 로컬 알림 설정
        if notificationsEnabled {
            // 시간표 데이터 가져오기 및 로컬 알림 설정
            LocalNotificationManager.shared.fetchAndSaveSchedule(grade: defaultGrade, classNumber: defaultClass)
        } else {
            // 알림이 비활성화된 경우 보류 중인 알림 제거
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        
        showInitialSetup = false
    }
}

struct InitialSetupView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InitialSetupView(showInitialSetup: .constant(true))
                .preferredColorScheme(.light)
                .environment(\.locale, .init(identifier: "en"))
                .previewDisplayName("English - Light Mode")

            InitialSetupView(showInitialSetup: .constant(true))
                .preferredColorScheme(.dark)
                .environment(\.locale, .init(identifier: "ko"))
                .previewDisplayName("Korean - Dark Mode")
        }
    }
}
