import SwiftUI
import UserNotifications

struct InitialSetupView: View {
    @Binding var showInitialSetup: Bool
    @State private var defaultGrade: Int = 1
    @State private var defaultClass: Int = 1
    @State private var notificationsEnabled: Bool = true
    @State private var physicalEducationAlertEnabled: Bool = true
    @State private var physicalEducationAlertTime: Date = {
        // 기본값으로 오전 7시 설정
        let calendar = Calendar.current
        let components = DateComponents(hour: 7, minute: 0)
        return calendar.date(from: components) ?? Date()
    }()
    
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
                
                Section(header: Text("체육 수업 알림 설정")) {
                    Toggle("체육 수업 알림 활성화", isOn: $physicalEducationAlertEnabled)
                    
                    if physicalEducationAlertEnabled {
                        DatePicker("알림 시간", selection: $physicalEducationAlertTime, displayedComponents: .hourAndMinute)
                    }
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
        
        // 체육 알림 설정 저장
        UserDefaults.standard.set(physicalEducationAlertEnabled, forKey: "physicalEducationAlertEnabled")
        
        // 시간 정보 저장
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: physicalEducationAlertTime)
        UserDefaults.standard.set(timeString, forKey: "physicalEducationAlertTime")
        
        // 로컬 알림 설정
        if notificationsEnabled {
            // 시간표 데이터 가져오기 및 로컬 알림 설정
            LocalNotificationManager.shared.fetchAndSaveSchedule(grade: defaultGrade, classNumber: defaultClass)
            
            // 체육 알림 설정
            if physicalEducationAlertEnabled {
                PhysicalEducationAlertManager.shared.scheduleAlerts()
            }
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
