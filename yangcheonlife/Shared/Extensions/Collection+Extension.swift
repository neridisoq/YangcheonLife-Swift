import Foundation

// MARK: - Collection 확장
extension Collection {
    /// 안전한 인덱스 접근
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Array 확장
extension Array {
    /// 빈 배열이 아닌 경우에만 접근 가능한 첫 번째 요소
    var safeFirst: Element? {
        return isEmpty ? nil : first
    }
    
    /// 빈 배열이 아닌 경우에만 접근 가능한 마지막 요소
    var safeLast: Element? {
        return isEmpty ? nil : last
    }
    
    /// 중복 제거 (Equatable 요소)
    func removingDuplicates() -> [Element] where Element: Equatable {
        var result: [Element] = []
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
    
    /// 조건에 맞는 첫 번째 인덱스 찾기
    func firstIndex(where predicate: (Element) -> Bool) -> Int? {
        for (index, element) in enumerated() {
            if predicate(element) {
                return index
            }
        }
        return nil
    }
}

// MARK: - Array<ScheduleItem> 확장
extension Array where Element == ScheduleItem {
    /// 특정 교시의 수업 찾기
    func findClass(for period: Int) -> ScheduleItem? {
        return first { $0.period == period }
    }
    
    /// 특정 과목의 수업 시간들 찾기
    func findClasses(for subject: String) -> [ScheduleItem] {
        return filter { $0.subject.contains(subject) }
    }
    
    /// 체육 수업이 있는지 확인
    var hasPhysicalEducation: Bool {
        return contains { $0.subject.contains("체육") || $0.subject.contains("PE") }
    }
    
    /// 빈 수업 시간 개수
    var emptyPeriods: Int {
        return filter { $0.subject.isEmpty }.count
    }
    
    /// 수업이 있는 마지막 교시
    var lastPeriodWithClass: Int? {
        return filter { !$0.subject.isEmpty }
            .map { $0.period }
            .max()
    }
}