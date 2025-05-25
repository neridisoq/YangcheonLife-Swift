import SwiftUI
import UserNotifications
import NetworkExtension
import WidgetKit

struct SettingsTabView: View {
    @State private var defaultGrade: Int = UserDefaults.standard.integer(forKey: "defaultGrade")
    @State private var defaultClass: Int = UserDefaults.standard.integer(forKey: "defaultClass")
    @State private var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var physicalEducationAlertEnabled: Bool = UserDefaults.standard.bool(forKey: "physicalEducationAlertEnabled")
    @State private var physicalEducationAlertTime: Date = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let timeString = UserDefaults.standard.string(forKey: "physicalEducationAlertTime"),
           let date = formatter.date(from: timeString) {
            return date
        } else {
            let calendar = Calendar.current
            let components = DateComponents(hour: 7, minute: 0)
            return calendar.date(from: components) ?? Date()
        }
    }()
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
                    
                    NavigationLink("탐구/기초 과목 선택", destination: SubjectSelectionView())
                    
                    NavigationLink("학교 Wi-Fi 연결", destination: WiFiConnectionView())
                    
                    ColorPicker(NSLocalizedString("ColorPicker", comment: ""), selection: $cellBackgroundColor)
                        .onChange(of: cellBackgroundColor) { newColor in
                            saveCellBackgroundColor(newColor)
                            updateSharedUserDefaults()
                        }
                }
                
                Section(header: Text(NSLocalizedString("Alert", comment: ""))) {
                    Toggle(NSLocalizedString("Alert Settings", comment: ""), isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { value in
                            UserDefaults.standard.set(value, forKey: "notificationsEnabled")
                            if value {
                                updateLocalScheduleAndNotifications()
                            } else {
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                            updateSharedUserDefaults()
                        }
                    
                    Toggle("체육 수업 알림 활성화", isOn: $physicalEducationAlertEnabled)
                        .onChange(of: physicalEducationAlertEnabled) { value in
                            UserDefaults.standard.set(value, forKey: "physicalEducationAlertEnabled")
                            if value && notificationsEnabled {
                                Task {
                                    await NotificationService.shared.schedulePhysicalEducationAlerts()
                                }
                            } else {
                                Task {
                                    await NotificationService.shared.removePhysicalEducationAlerts()
                                }
                            }
                            updateSharedUserDefaults()
                        }
                    
                    if physicalEducationAlertEnabled {
                        DatePicker("체육 알림 시간", selection: $physicalEducationAlertTime, displayedComponents: .hourAndMinute)
                            .onChange(of: physicalEducationAlertTime) { newValue in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                let timeString = formatter.string(from: newValue)
                                UserDefaults.standard.set(timeString, forKey: "physicalEducationAlertTime")
                                
                                if physicalEducationAlertEnabled && notificationsEnabled {
                                    Task {
                                        await NotificationService.shared.schedulePhysicalEducationAlerts()
                                    }
                                }
                                updateSharedUserDefaults()
                            }
                    }
                }
                
                Section(header: Text(NSLocalizedString("Link", comment: ""))) {
                    Link(NSLocalizedString("Privacy Policy", comment: ""), destination: URL(string: "https://yangcheon.sen.hs.kr/dggb/module/policy/selectPolicyDetail.do?policyTypeCode=PLC002&menuNo=75574")!)
                    Link(NSLocalizedString("Goto School Web", comment: ""), destination: URL(string: "https://yangcheon.sen.hs.kr")!)
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
                    Link(NSLocalizedString("개발자 인스타그램", comment: ""), destination: URL(string: "https://instagram.com/neridisoq_")!)
                }
            }
            .navigationBarTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadSettings()
            if notificationsEnabled {
                updateLocalScheduleAndNotifications()
            }
        }
        .onDisappear {
            updateSharedUserDefaults()
        }
    }
    
    private func loadSettings() {
        defaultGrade = UserDefaults.standard.integer(forKey: "defaultGrade")
        defaultClass = UserDefaults.standard.integer(forKey: "defaultClass")
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        physicalEducationAlertEnabled = UserDefaults.standard.bool(forKey: "physicalEducationAlertEnabled")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let timeString = UserDefaults.standard.string(forKey: "physicalEducationAlertTime"),
           let date = formatter.date(from: timeString) {
            physicalEducationAlertTime = date
        }
    }
    
    private func sendEmail() {
        let email = "neridisoq@icloud.com"
        if let url = URL(string: "mailto:\(email)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    private func updateLocalScheduleAndNotifications() {
        if notificationsEnabled {
            Task {
                await ScheduleService.shared.updateNotifications(grade: defaultGrade, classNumber: defaultClass)
            }
            
            if physicalEducationAlertEnabled {
                Task {
                    await NotificationService.shared.schedulePhysicalEducationAlerts()
                }
            }
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
    
    private func updateSharedUserDefaults() {
        print("🔄 설정 변경: 위젯 데이터 동기화 시작")
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        SharedUserDefaults.shared.printAllValues()
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ 위젯 타임라인 리로드 요청 완료")
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
                Task {
                    await ScheduleService.shared.updateNotifications(grade: defaultGrade, classNumber: defaultClass)
                }
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
            
            SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

struct SettingsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTabView()
            .previewDisplayName("설정 탭")
    }
}