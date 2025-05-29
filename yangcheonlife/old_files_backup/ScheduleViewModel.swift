import SwiftUI
import Combine

class ScheduleViewModel: ObservableObject {
    @Published var schedules: [[ScheduleItem]] = []
    // 현재 시간표 정보를 저장하는 프로퍼티 추가
    @Published var currentGrade: Int = 0
    @Published var currentClass: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 초기화 시 저장소2에서 로드
        if let savedData = ScheduleManager.shared.loadDataStore() {
            self.schedules = savedData.schedules
            self.currentGrade = savedData.grade
            self.currentClass = savedData.classNumber
        }
    }
    
    func loadSchedule(grade: Int, classNumber: Int) {
        // 현재 표시 중인 학년/반 정보 업데이트
        self.currentGrade = grade
        self.currentClass = classNumber
        
        // 저장소2에서 시간표 데이터 확인
        if let savedData = ScheduleManager.shared.loadDataStore() {
            // 요청한 학년/반과 캐시된 데이터가 일치하는지 확인
            if savedData.grade == grade && savedData.classNumber == classNumber {
                self.schedules = savedData.schedules
                return // 캐시된 데이터가 있으면 서버 요청 생략
            }
        }
        
        // 서버에서 시간표 데이터 직접 가져오기 (사용자 설정에 영향 없음)
        let urlString = "https://comsi.helgisnw.me/\(grade)/\(classNumber)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  error == nil else {
                print("시간표 데이터 요청 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                return
            }
            
            do {
                // 서버 응답 데이터 파싱
                let schedules = try JSONDecoder().decode([[ScheduleItem]].self, from: data)
                
                // UI 업데이트
                DispatchQueue.main.async {
                    self?.schedules = schedules
                }
            } catch {
                print("시간표 데이터 파싱 실패: \(error)")
            }
        }.resume()
    }
    
    // 화면 표시용 시간표 데이터 가져오기 (알림 설정에 영향 없음)
    private func fetchScheduleForDisplay(grade: Int, classNumber: Int) {
        // 서버에서 시간표 가져오기
        let urlString = "https://comsi.helgisnw.me/\(grade)/\(classNumber)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("시간표 데이터 요청 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                return
            }
            
            do {
                // 서버 응답 데이터 파싱
                let schedules = try JSONDecoder().decode([[ScheduleItem]].self, from: data)
                
                // UI 업데이트
                DispatchQueue.main.async {
                    self.schedules = schedules
                }
            } catch {
                print("시간표 데이터 파싱 실패: \(error)")
            }
        }.resume()
    }
}

// 데이터 업데이트 알림을 위한 NotificationCenter 확장
extension Notification.Name {
    static let scheduleDataDidUpdate = Notification.Name("scheduleDataDidUpdate")
}
