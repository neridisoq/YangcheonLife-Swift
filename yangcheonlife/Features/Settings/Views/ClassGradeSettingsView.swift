// ClassGradeSettingsView.swift - 학년/반 설정 뷰 (원래 기능)
import SwiftUI
import WidgetKit
import UserNotifications

struct ClassGradeSettingsView: View {
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

// MARK: - 미리보기
struct ClassGradeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ClassGradeSettingsView(
                defaultGrade: .constant(1),
                defaultClass: .constant(1),
                notificationsEnabled: .constant(true)
            )
            .environmentObject(ScheduleService.shared)
            .environmentObject(NotificationService.shared)
        }
        .previewDisplayName("학년/반 설정")
    }
}