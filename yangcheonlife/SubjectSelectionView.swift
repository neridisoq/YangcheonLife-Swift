import SwiftUI

struct SubjectSelectionView: View {
    @State private var selectedGrade: Int = UserDefaults.standard.integer(forKey: "defaultGrade")
    @State private var selectedGroupType: String = UserDefaults.standard.string(forKey: "selectedGroupType") ?? "h반"
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("학년 선택")) {
                    Picker("학년", selection: $selectedGrade) {
                        Text("2학년").tag(2)
                        Text("3학년").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedGrade) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "defaultGrade")
                    }
                }
                
                Section(header: Text("분반 선택")) {
                    Picker("분반 유형", selection: $selectedGroupType) {
                        Text("h반").tag("h반")
                        Text("t반").tag("t반")
                        Text("나머지반").tag("나머지반")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedGroupType) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "selectedGroupType")
                    }
                }
                
                Section(header: Text("세부 반 선택")) {
                    if selectedGrade == 2 {
                        if selectedGroupType == "h반" {
                            NavigationLink("A 반", destination: ClassSubjectSelectionView(className: "A 반", subjects: grade2ClassASubjects))
                            NavigationLink("B 반", destination: ClassSubjectSelectionView(className: "B 반", subjects: grade2ClassBSubjects))
                            NavigationLink("C 반", destination: ClassSubjectSelectionView(className: "C 반", subjects: grade2ClassCSubjects))
                            NavigationLink("D 반", destination: ClassSubjectSelectionView(className: "D 반", subjects: grade2ClassDSubjects))
                        } else if selectedGroupType == "t반" {
                            NavigationLink("E 반", destination: ClassSubjectSelectionView(className: "E 반", subjects: grade2ClassESubjects))
                            NavigationLink("F 반", destination: ClassSubjectSelectionView(className: "F 반", subjects: grade2ClassFSubjects))
                            NavigationLink("G 반", destination: ClassSubjectSelectionView(className: "G 반", subjects: grade2ClassGSubjects))
                            NavigationLink("H 반", destination: ClassSubjectSelectionView(className: "H 반", subjects: grade2ClassHSubjects))
                        } else if selectedGroupType == "나머지반" {
                            NavigationLink("I 반", destination: ClassSubjectSelectionView(className: "I 반", subjects: grade2ClassISubjects))
                            NavigationLink("J 반", destination: ClassSubjectSelectionView(className: "J 반", subjects: grade2ClassJSubjects))
                            NavigationLink("K 반", destination: ClassSubjectSelectionView(className: "K 반", subjects: grade2ClassKSubjects))
                            NavigationLink("L 반", destination: ClassSubjectSelectionView(className: "L 반", subjects: grade2ClassLSubjects))
                            NavigationLink("M 반", destination: ClassSubjectSelectionView(className: "M 반", subjects: grade2ClassMSubjects))
                            NavigationLink("N 반", destination: ClassSubjectSelectionView(className: "N 반", subjects: grade2ClassNSubjects))
                        }
                    } else if selectedGrade == 3 {
                        if selectedGroupType == "h반" {
                            NavigationLink("A 반", destination: ClassSubjectSelectionView(className: "A 반", subjects: grade3ClassASubjects))
                            NavigationLink("B 반", destination: ClassSubjectSelectionView(className: "B 반", subjects: grade3ClassBSubjects))
                            NavigationLink("C 반", destination: ClassSubjectSelectionView(className: "C 반", subjects: grade3ClassCSubjects))
                            NavigationLink("G 반", destination: ClassSubjectSelectionView(className: "G 반", subjects: grade3ClassGSubjects))
                            NavigationLink("H 반", destination: ClassSubjectSelectionView(className: "H 반", subjects: grade3ClassHSubjects))
                            NavigationLink("I 반", destination: ClassSubjectSelectionView(className: "I 반", subjects: grade3ClassISubjects))
                        } else if selectedGroupType == "t반" {
                            NavigationLink("D 반", destination: ClassSubjectSelectionView(className: "D 반", subjects: grade3ClassDSubjects))
                            NavigationLink("E 반", destination: ClassSubjectSelectionView(className: "E 반", subjects: grade3ClassESubjects))
                            NavigationLink("F 반", destination: ClassSubjectSelectionView(className: "F 반", subjects: grade3ClassFSubjects))
                            NavigationLink("J 반", destination: ClassSubjectSelectionView(className: "J 반", subjects: grade3ClassJSubjects))
                            NavigationLink("K 반", destination: ClassSubjectSelectionView(className: "K 반", subjects: grade3ClassKSubjects))
                            NavigationLink("L 반", destination: ClassSubjectSelectionView(className: "L 반", subjects: grade3ClassLSubjects))
                            NavigationLink("M 반", destination: ClassSubjectSelectionView(className: "M 반", subjects: grade3ClassMSubjects))
                        } else if selectedGroupType == "나머지반" {
                            NavigationLink("N 반", destination: ClassSubjectSelectionView(className: "N 반", subjects: grade3ClassNSubjects))
                            NavigationLink("O 반", destination: ClassSubjectSelectionView(className: "O 반", subjects: grade3ClassOSubjects))
                        }
                    }
                }
            }
            .navigationBarTitle("탐구/기초 과목 선택")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        selectedGrade = UserDefaults.standard.integer(forKey: "defaultGrade")
        selectedGroupType = UserDefaults.standard.string(forKey: "selectedGroupType") ?? "h반"
    }
    
    // 2학년 각 반별 과목 리스트
    let grade2ClassASubjects = ["선택 없음", "물리I/202", "생명I/204", "여지/201", "지구I/205", "화학I/203"];
    let grade2ClassBSubjects = ["선택 없음", "물리I/202", "생명I/204", "여지/201", "지구I/205", "화학I/203"];
    let grade2ClassCSubjects = ["선택 없음", "물리I/202", "여지/201", "지구I/205", "화학I/203"];
    let grade2ClassDSubjects = ["선택 없음", "물리I/202", "생명I/204", "여지/201", "지구I/205", "화학I/210"];
    let grade2ClassESubjects = ["선택 없음", "물리I/209", "생활과학/211", "여지/다목적실A", "윤사/208", "정법/207", "지구I/210", "한지/206"];
    let grade2ClassFSubjects = ["선택 없음", "물리I/209", "생활과학/211", "여지/다목적실A", "윤사/208", "정법/207", "지구I/210", "한지/206"];
    let grade2ClassGSubjects = ["선택 없음", "경제/209", "생명I/211", "생활과학/다목적실A", "세계사/206", "윤사/208", "정법/207", "화학I/210"];
    let grade2ClassHSubjects = ["선택 없음", "경제/209", "생명I/211", "생활과학/207", "세계사/206", "여지/다목적실A", "윤사/208"];
    let grade2ClassISubjects = ["선택 없음", "기하/207", "심화국어/206"];
    let grade2ClassJSubjects = ["선택 없음", "기하/209", "심화국어/208", "영어문화/다목적실B"];
    let grade2ClassKSubjects = ["선택 없음", "기하/211", "심화국어/홈베이스B", "영어문화/210"];
    let grade2ClassLSubjects = ["선택 없음", "일본어I/206", "중국어I/207"];
    let grade2ClassMSubjects = ["선택 없음", "일본어I/208", "중국어I/209"];
    let grade2ClassNSubjects = ["선택 없음", "일본어I/210", "중국어I/다목적실B"];
    
    // 3학년 각 반별 과목 리스트
    let grade3ClassASubjects = ["선택 없음", "과학사/꿈담카페B", "물리/302", "사문/304", "사문탐/303", "생명/305", "세지/306", "지구/301"];
    let grade3ClassBSubjects = ["선택 없음", "과학사/꿈담카페B", "물리/302", "사문/305", "사문탐/306", "생윤/301", "지구/303", "화학/304"];
    let grade3ClassCSubjects = ["선택 없음", "물리/302", "사문/305", "사문탐/303", "생명/306", "생윤/301", "화학/304"];
    let grade3ClassDSubjects = ["선택 없음", "과학사/홈베이스B", "사문탐/309", "생명/310", "생윤/308", "세지/307", "지구/311"];
    let grade3ClassESubjects = ["선택 없음", "과학사/홈베이스B", "물리/310", "사문/308", "사문탐/309", "생윤/307", "지구/311"];
    let grade3ClassFSubjects = ["선택 없음", "동아사/홈베이스B", "물리/309", "사문/308", "생명/310", "지구/311", "화학/307"];
    let grade3ClassGSubjects = ["선택 없음", "고전읽기/301", "미적분/302", "수과탐/303", "영독작/305", "AI수학/304", "진로영어/306"];
    let grade3ClassHSubjects = ["선택 없음", "고전읽기/301", "미적분/302", "수과탐/303", "영독작/305", "영어회화/304", "진로영어H1/306", "진로영어H2/꿈담카페B"];
    let grade3ClassISubjects = ["선택 없음", "경제수학/301", "미적분I1/302", "미적분I2/304", "수과탐/303", "영독작/305", "AI수학/꿈담카페B", "진로영어/306"];
    let grade3ClassJSubjects = ["선택 없음", "미적분/310", "수과탐/309", "영독작/307", "영어회화/308", "진로영어/311"];
    let grade3ClassKSubjects = ["선택 없음", "경제수학/308", "미적분/309", "영독작/310", "AI수학/307", "진로영어/311"];
    let grade3ClassLSubjects = ["선택 없음", "고전읽기/311", "미적분/310", "수과탐/309", "영독작/308", "AI수학/홈베이스B", "확통/307"];
    let grade3ClassMSubjects = ["선택 없음", "고전읽기/308", "미적분/309", "수과탐/310", "AI수학/홈베이스B", "진로영어/311", "확통/307"];
    let grade3ClassNSubjects = ["선택 없음", "언매/307", "화작N1/308", "화작N2/홈베이스B"];
    let grade3ClassOSubjects = ["선택 없음", "언매/311", "화작/310"];
}

struct ClassSubjectSelectionView: View {
    let className: String
    let subjects: [String]
    @State private var selectedSubject: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("\(className) 과목 선택")) {
                Picker("과목 선택", selection: $selectedSubject) {
                    ForEach(subjects, id: \.self) { subject in
                        Text(subject).tag(subject)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .onChange(of: selectedSubject) { newValue in
                    // 선택한 과목을 UserDefaults에 저장
                    UserDefaults.standard.set(newValue, forKey: "selected\(className)Subject")
                    
                    // 알림 재설정 트리거
                    triggerNotificationReset()
                }
                .onAppear {
                    // 이전에 저장된 과목 불러오기
                    selectedSubject = UserDefaults.standard.string(forKey: "selected\(className)Subject") ?? subjects.first ?? "선택 없음"
                }
            }
            
            if selectedSubject != "선택 없음" && selectedSubject != "" {
                let components = selectedSubject.components(separatedBy: "/")
                if components.count == 2 {
                    Section(header: Text("선택된 정보")) {
                        Text("과목명: \(components[0])")
                        Text("교실: \(components[1])")
                    }
                }
            }
        }
        .navigationBarTitle("\(className) 설정", displayMode: .inline)
    }
    
    // 과목 선택 시 알림 재설정을 트리거하는 함수
    private func triggerNotificationReset() {
        // 설정된 학년/반 정보 가져오기
        let grade = UserDefaults.standard.integer(forKey: "defaultGrade")
        let classNumber = UserDefaults.standard.integer(forKey: "defaultClass")
        
        // 알림이 활성화되어 있고, 유효한 학년/반 정보가 있는 경우에만 실행
        if UserDefaults.standard.bool(forKey: "notificationsEnabled") && grade > 0 && classNumber > 0 {
            // 변경사항을 저장소에 반영 후 알림 재설정
            if let savedData = ScheduleManager.shared.loadDataStore() {
                if savedData.grade == grade && savedData.classNumber == classNumber {
                    // 현재 설정과 일치하는 데이터가 있는 경우 처리
                    let customizedSchedules = ScheduleManager.shared.applyCurrentSubjectCustomization(schedules: savedData.schedules)
                    
                    let updatedData = ScheduleData(
                        grade: grade,
                        classNumber: classNumber,
                        lastUpdated: Date(),
                        schedules: customizedSchedules
                    )
                    
                    // 저장소2에 업데이트된 데이터 저장
                    ScheduleManager.shared.saveToDataStore(updatedData)
                    
                    // 알림 재설정
                    ScheduleManager.shared.resetNotifications(scheduleData: updatedData) { _ in
                        // 완료 처리 (필요시 구현)
                    }
                    
                    // 업데이트 알림 발송
                    NotificationCenter.default.post(name: .scheduleDataDidUpdate, object: nil)
                }
            }
        }
    }
}

struct SubjectSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SubjectSelectionView()
    }
}
