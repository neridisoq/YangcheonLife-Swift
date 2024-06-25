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
                Section(header: Text("학년 반 설정")) {
                    Picker("학년", selection: $defaultGrade) {
                        ForEach(1..<4) { grade in
                            Text("\(grade)학년").tag(grade)
                        }
                    }
                    
                    Picker("반", selection: $defaultClass) {
                        ForEach(1..<12) { classNumber in
                            Text("\(classNumber)반").tag(classNumber)
                        }
                    }
                }
                
                Section(header: Text("탐구 과목 선택 (2학년만 해당)")) {
                    Picker("탐구B", selection: $selectedSubjectB) {
                        ForEach(subjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    
                    Picker("탐구C", selection: $selectedSubjectC) {
                        ForEach(subjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    
                    Picker("탐구D", selection: $selectedSubjectD) {
                        ForEach(subjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                }
                
                Section(header: Text("알림 설정")) {
                    Toggle("알림 설정", isOn: $notificationsEnabled)
                }
                
                Button(action: saveSettings) {
                    Text("설정 완료")
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
        InitialSetupView(showInitialSetup: .constant(true))
    }
}
