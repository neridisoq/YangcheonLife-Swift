// ScheduleViewModel.swift
import SwiftUI
import Combine

class ScheduleViewModel: ObservableObject {
    @Published var schedules: [[ScheduleItem]] = []
    
    func loadSchedule(grade: Int, classNumber: Int) {
        fetchSchedule(grade: grade, classNumber: classNumber) { schedules in
            self.schedules = schedules
        }
    }
    
    private func fetchSchedule(grade: Int, classNumber: Int, completion: @escaping ([[ScheduleItem]]) -> Void) {
        let urlString = "https://comsi.helgisnw.me/\(grade)/\(classNumber)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let schedules = try JSONDecoder().decode([[ScheduleItem]].self, from: data)
                    DispatchQueue.main.async {
                        completion(schedules)
                    }
                } catch {
                    print("Error decoding schedule data: \(error)")
                }
            } else if let error = error {
                print("HTTP request failed: \(error)")
            }
        }.resume()
    }
}
