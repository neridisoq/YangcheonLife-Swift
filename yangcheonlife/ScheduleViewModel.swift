//ScheduleViewModel.swift
import SwiftUI
import Combine

class ScheduleViewModel: ObservableObject {
    @Published var schedules: [[ScheduleItem]] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 초기화 시 로컬에 저장된 시간표가 있으면 로드
        loadLocalSchedule()
    }
    
    func loadSchedule(grade: Int, classNumber: Int) {
        // 먼저, 로컬에 저장된 데이터 확인
        if let savedSchedules = loadLocalSchedule(), !savedSchedules.isEmpty {
            self.schedules = savedSchedules
        }
        
        // 그런 다음, 서버에서 최신 데이터 가져오기 시도
        fetchSchedule(grade: grade, classNumber: classNumber) { [weak self] fetchedSchedules in
            if !fetchedSchedules.isEmpty {
                self?.schedules = fetchedSchedules
                self?.saveLocalSchedule(fetchedSchedules)
            }
        }
    }
    
    private func fetchSchedule(grade: Int, classNumber: Int, completion: @escaping ([[ScheduleItem]]) -> Void) {
        let urlString = "https://comsi.helgisnw.me/\(grade)/\(classNumber)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [[ScheduleItem]].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("시간표 로드 완료")
                case .failure(let error):
                    print("시간표 로드 실패: \(error)")
                }
            }, receiveValue: { schedules in
                completion(schedules)
            })
            .store(in: &cancellables)
    }
    
    // 로컬에 시간표 저장
    private func saveLocalSchedule(_ schedules: [[ScheduleItem]]) {
        do {
            let data = try JSONEncoder().encode(schedules)
            UserDefaults.standard.set(data, forKey: "cachedSchedule")
            // 마지막 업데이트 시간 저장
            UserDefaults.standard.set(Date(), forKey: "lastScheduleUpdateTime")
        } catch {
            print("시간표 저장 실패: \(error)")
        }
    }
    
    // 로컬에서 시간표 로드
    private func loadLocalSchedule() -> [[ScheduleItem]]? {
        guard let data = UserDefaults.standard.data(forKey: "cachedSchedule") else {
            return nil
        }
        
        do {
            let decodedSchedule = try JSONDecoder().decode([[ScheduleItem]].self, from: data)
            return decodedSchedule
        } catch {
            print("시간표 로드 실패: \(error)")
            return nil
        }
    }
}
