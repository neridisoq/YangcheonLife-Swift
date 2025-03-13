import Foundation
import Combine

public class NeisAPIManager {
    public static let shared = NeisAPIManager()
    
    private let apiKey = "1bd529acc7a54078972b1e4dc99556b3"
    private let baseURL = "https://open.neis.go.kr/hub/mealServiceDietInfo"
    
    private init() {}
    
    public func fetchMeal(date: Date, mealType: MealType) -> AnyPublisher<MealInfo?, Error> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "\(baseURL)?Type=json&pIndex=1&pSize=100&ATPT_OFCDC_SC_CODE=B10&SD_SCHUL_CODE=7010209&MMEAL_SC_CODE=\(mealType.rawValue)&MLSV_YMD=\(dateString)&KEY=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: NeisResponse.self, decoder: JSONDecoder())
            .map { response in
                if let error = response.RESULT, error.CODE == "INFO-200" {
                    // 데이터 없음
                    return nil
                }
                
                if let mealInfo = response.mealServiceDietInfo?[1].row?.first {
                    // HTML 태그 제거 및 개행 문자 변환
                    let menuText = mealInfo.DDISH_NM
                        .replacingOccurrences(of: "<br/>", with: "\n")
                        .replacingOccurrences(of: " \\([0-9.]+\\)", with: "", options: .regularExpression)
                    
                    return MealInfo(
                        mealType: mealType,
                        menuText: menuText,
                        calInfo: mealInfo.CAL_INFO ?? ""
                    )
                }
                
                return nil
            }
            .catch { error in
                print("급식 정보 가져오기 실패: \(error)")
                return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

// NEIS API 응답 구조체
private struct NeisResponse: Codable {
    var mealServiceDietInfo: [[String: Any]]?
    var RESULT: NeisError?
    
    enum CodingKeys: String, CodingKey {
        case mealServiceDietInfo
        case RESULT
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 오류 응답인 경우
        if let errorContainer = try? container.decode([String: String].self, forKey: .RESULT) {
            self.RESULT = NeisError(CODE: errorContainer["CODE"] ?? "", MESSAGE: errorContainer["MESSAGE"] ?? "")
            self.mealServiceDietInfo = nil
            return
        }
        
        self.RESULT = nil
        
        // 성공 응답인 경우
        if let mealServiceDietInfo = try? container.decode([NeisServiceInfo].self, forKey: .mealServiceDietInfo) {
            self.mealServiceDietInfo = mealServiceDietInfo.map { $0.toDictionary() }
        } else {
            self.mealServiceDietInfo = nil
        }
    }
}

private struct NeisError: Codable {
    let CODE: String
    let MESSAGE: String
}

private struct NeisServiceInfo: Codable {
    let head: [NeisHead]?
    let row: [NeisMealInfo]?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let head = head {
            dict["head"] = head
        }
        if let row = row {
            dict["row"] = row
        }
        return dict
    }
}

private struct NeisHead: Codable {
    let list_total_count: Int?
    let RESULT: NeisError?
}

private struct NeisMealInfo: Codable {
    let MMEAL_SC_CODE: String
    let MLSV_YMD: String
    let DDISH_NM: String
    let CAL_INFO: String?
}