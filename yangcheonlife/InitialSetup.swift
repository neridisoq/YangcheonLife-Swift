import SwiftUI
import Firebase

struct InitialSetupView: View {
    @Binding var showInitialSetup: Bool
    @State private var defaultGrade: Int = 1
    @State private var defaultClass: Int = 1
    @State private var notificationsEnabled: Bool = true
    @State private var selectedSubjectB: String = "없음"
    @State private var selectedSubjectC: String = "없음"
    @State private var selectedSubjectD: String = "없음"
    
    let subjects = [
        "없음", "물리", "화학", "생명과학", "지구과학", "윤사", "정치와 법", "경제", "세계사", "한국지리", "탐구B", "탐구C", "탐구D"
    ]
    
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
                
                Section(header: Text(NSLocalizedString("SubjectSelection", comment: ""))) {
                    Picker(NSLocalizedString("Subject B", comment: ""), selection: $selectedSubjectB) {
                        ForEach(subjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    
                    Picker(NSLocalizedString("Subject C", comment: ""), selection: $selectedSubjectC) {
                        ForEach(subjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    
                    Picker(NSLocalizedString("Subject D", comment: ""), selection: $selectedSubjectD) {
                        ForEach(subjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                }
                
                Section(header: Text(NSLocalizedString("Alert", comment: ""))) {
                    Toggle(NSLocalizedString("Alert Settings", comment: ""), isOn: $notificationsEnabled)
                }
                
                Button(action: saveSettings) {
                    Text(NSLocalizedString("Done", comment: ""))
                }
            }
            .navigationBarTitle("초기 설정")
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(defaultGrade, forKey: "defaultGrade")
        UserDefaults.standard.set(defaultClass, forKey: "defaultClass")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(selectedSubjectB, forKey: "selectedSubjectB")
        UserDefaults.standard.set(selectedSubjectC, forKey: "selectedSubjectC")
        UserDefaults.standard.set(selectedSubjectD, forKey: "selectedSubjectD")
        UserDefaults.standard.set(true, forKey: "initialSetupCompleted")
        
        // FCM 토픽 구독
        if notificationsEnabled {
            subscribeToCurrentTopic()
        }
        
        showInitialSetup = false
    }

    private func subscribeToCurrentTopic() {
        let topic = "\(defaultGrade)-\(defaultClass)"
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Failed to subscribe to topic \(topic): \(error)")
            } else {
                print("Subscribed to topic \(topic)")
            }
        }
    }
}

struct InitialSetupView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InitialSetupView(showInitialSetup: .constant(true))
                .preferredColorScheme(.light)
                .environment(\.locale, .init(identifier: "en"))
                .previewDisplayName("English - Dark Mode")

            InitialSetupView(showInitialSetup: .constant(true))
                .preferredColorScheme(.dark)
                .environment(\.locale, .init(identifier: "ko"))
                .previewDisplayName("Korean - Dark Mode")
        }
    }
}
