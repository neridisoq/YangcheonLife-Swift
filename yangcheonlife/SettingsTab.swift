import SwiftUI
import UserNotifications

struct SettingsTab: View {
    @State private var defaultGrade: Int = UserDefaults.standard.integer(forKey: "defaultGrade")
    @State private var defaultClass: Int = UserDefaults.standard.integer(forKey: "defaultClass")
    @State private var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var cellBackgroundColor: Color = {
        if let data = UserDefaults.standard.data(forKey: "cellBackgroundColor"),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            return Color(uiColor)
        }
        return Color.yellow.opacity(0.3)
    }()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(NSLocalizedString("Settings", comment: ""))) {
                    NavigationLink(NSLocalizedString("ClassSettings", comment: ""), destination: ClassAndGradeView(defaultGrade: $defaultGrade, defaultClass: $defaultClass, notificationsEnabled: $notificationsEnabled))
                    
                    // 기존 탐구 과목 선택 대신 새로운 과목 선택 뷰로 연결
                    NavigationLink("탐구/기초 과목 선택", destination: SubjectSelectionView())
                    
                    ColorPicker(NSLocalizedString("ColorPicker", comment: ""), selection: $cellBackgroundColor)
                        .onChange(of: cellBackgroundColor) { newColor in
                            saveCellBackgroundColor(newColor)
                        }
                }
                
                Section(header: Text(NSLocalizedString("Link", comment: ""))) {
                    Link(NSLocalizedString("Privacy Policy", comment: ""), destination: URL(string: "https://yangcheon.sen.hs.kr/dggb/module/policy/selectPolicyDetail.do?policyTypeCode=PLC002&menuNo=75574")!)
                    Link(NSLocalizedString("Goto School Web", comment: ""), destination: URL(string: "https://yangcheon.sen.hs.kr")!)
                }
                
                Section(header: Text(NSLocalizedString("Alert", comment: ""))) {
                    Toggle(NSLocalizedString("Alert Settings", comment: ""), isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { value in
                            UserDefaults.standard.set(value, forKey: "notificationsEnabled")
                            if value {
                                // 알림 활성화시 로컬 알림 설정
                                updateLocalScheduleAndNotifications()
                            } else {
                                // 알림 비활성화시 모든 알림 제거
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }
                }
                
                Section(header: Text(NSLocalizedString("Support", comment: ""))) {
                    Button(action: {
                        sendEmail()
                    }) {
                        HStack {
                            Text(NSLocalizedString("Supportto", comment: ""))
                            Spacer()
                            Image(systemName: "envelope")
                        }
                    }
                }
            }
            .navigationBarTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadSettings()
            if notificationsEnabled {
                // 설정 화면 진입시 알림 설정 확인
                updateLocalScheduleAndNotifications()
            }
        }
    }
    
    private func loadSettings() {
        defaultGrade = UserDefaults.standard.integer(forKey: "defaultGrade")
        defaultClass = UserDefaults.standard.integer(forKey: "defaultClass")
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    private func sendEmail() {
        let email = "neridisoq@icloud.com"
        if let url = URL(string: "mailto:\(email)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    // Firebase 토픽 구독 함수는 제거하고 대신 로컬 시간표와 알림을 관리하는 함수로 변경
    private func updateLocalScheduleAndNotifications() {
        // 시간표 데이터 가져오기 및 알림 설정 업데이트
        if notificationsEnabled {
            LocalNotificationManager.shared.fetchAndSaveSchedule(grade: defaultGrade, classNumber: defaultClass)
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    private func saveCellBackgroundColor(_ color: Color) {
        if let uiColor = UIColor(color).cgColor.copy(alpha: 0.3) {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(cgColor: uiColor), requiringSecureCoding: false) {
                UserDefaults.standard.set(data, forKey: "cellBackgroundColor")
            }
        }
    }
}

struct ClassAndGradeView: View {
    @Binding var defaultGrade: Int
    @Binding var defaultClass: Int
    @Binding var notificationsEnabled: Bool

    var body: some View {
        Form {
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
        .navigationBarTitle(NSLocalizedString("ClassSettings", comment: ""), displayMode: .inline)
        .onDisappear {
            let oldGrade = UserDefaults.standard.integer(forKey: "defaultGrade")
            let oldClass = UserDefaults.standard.integer(forKey: "defaultClass")
            UserDefaults.standard.set(defaultGrade, forKey: "defaultGrade")
            UserDefaults.standard.set(defaultClass, forKey: "defaultClass")
            if notificationsEnabled {
                // 시간표와 알림 설정 업데이트
                LocalNotificationManager.shared.fetchAndSaveSchedule(grade: defaultGrade, classNumber: defaultClass)
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    
    // 로컬 알림 관련 함수로 대체
}
