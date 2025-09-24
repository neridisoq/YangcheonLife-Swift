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
            .onChange(of: defaultGrade) { newGrade in
                saveGradeClassSettings(grade: newGrade, classNumber: defaultClass)
            }
            
            Picker(NSLocalizedString("Class", comment: ""), selection: $defaultClass) {
                ForEach(1..<12) { classNumber in
                    Text(String(format: NSLocalizedString("ClassP", comment: ""), classNumber)).tag(classNumber)
                }
            }
            .onChange(of: defaultClass) { newClass in
                saveGradeClassSettings(grade: defaultGrade, classNumber: newClass)
            }
        }
        .navigationBarTitle(NSLocalizedString("ClassSettings", comment: ""), displayMode: .inline)
    }
    
    // MARK: - 학년반 설정 저장 메서드
    private func saveGradeClassSettings(grade: Int, classNumber: Int) {
        // UserDefaults에 즉시 저장
        UserDefaults.standard.set(grade, forKey: "defaultGrade")
        UserDefaults.standard.set(classNumber, forKey: "defaultClass")
        
        // 알림 업데이트
        if notificationsEnabled {
            Task {
                await ScheduleService.shared.updateNotifications(grade: grade, classNumber: classNumber)
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        
        // SharedUserDefaults 동기화
        SharedUserDefaults.shared.synchronizeFromStandardUserDefaults()
        
        // 다른 뷰들에게 변경사항 알림
        NotificationCenter.default.post(name: NSNotification.Name("GradeClassChanged"), object: nil)
        
        // 위젯 업데이트
        WidgetCenter.shared.reloadAllTimelines()
        
        // ScheduleService에 강제 새로고침 요청
        ScheduleService.shared.forceRefresh()
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