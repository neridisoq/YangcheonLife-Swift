import Foundation

public class NeisAPIManager {
    public static let shared = NeisAPIManager()
    
    private let apiKey = "1bd529acc7a54078972b1e4dc99556b3"
    private let baseURL = "https://open.neis.go.kr/hub/mealServiceDietInfo"
    
    private init() {}
    
    public func fetchMeal(date: Date, mealType: MealType, completion: @escaping (MealInfo?) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "\(baseURL)?Type=json&pIndex=1&pSize=100&ATPT_OFCDC_SC_CODE=B10&SD_SCHUL_CODE=7010209&MMEAL_SC_CODE=\(mealType.rawValue)&MLSV_YMD=\(dateString)&KEY=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("급식 정보 가져오기 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                completion(nil)
                return
            }
            
            do {
                // JSON 파싱
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // 오류 응답 확인
                    if let resultDict = json["RESULT"] as? [String: String],
                       resultDict["CODE"] == "INFO-200" {
                        // 데이터 없음
                        completion(nil)
                        return
                    }
                    
                    // 급식 정보 파싱
                    if let mealServiceInfo = json["mealServiceDietInfo"] as? [[String: Any]],
                       mealServiceInfo.count >= 2,
                       let rowsData = mealServiceInfo[1]["row"] as? [[String: Any]],
                       let firstRow = rowsData.first {
                        
                        let rawMenuText = firstRow["DDISH_NM"] as? String ?? ""
                        let menuText = rawMenuText
                            .replacingOccurrences(of: "<br/>", with: "\n")
                            .replacingOccurrences(of: "<![CDATA[", with: "")
                            .replacingOccurrences(of: "]]>", with: "")
                            // 알레르기 정보 제거 (숫자와 괄호)
                            .replacingOccurrences(of: " ?\\([0-9\\.]+\\)", with: "", options: .regularExpression)
                            // (양천) 제거
                            .replacingOccurrences(of: "\\(양천\\)", with: "", options: .regularExpression)
                            // (완) 제거
                            .replacingOccurrences(of: "\\(완\\)", with: "", options: .regularExpression)
                            // /자율 제거
                            .replacingOccurrences(of: "/자율", with: "")
                            // 남은 괄호와 괄호 안 내용 제거
                            .replacingOccurrences(of: " ?\\([^\\)]*\\)", with: "", options: .regularExpression)
                            // 중복 공백 제거
                            .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
                            // 줄바꿈 주변 공백 정리
                            .replacingOccurrences(of: " *\n *", with: "\n", options: .regularExpression)
                            // 양쪽 공백 제거
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        let calInfo = firstRow["CAL_INFO"] as? String ?? ""
                        
                        let mealInfo = MealInfo(
                            mealType: mealType,
                            menuText: menuText,
                            calInfo: calInfo
                        )
                        
                        completion(mealInfo)
                        return
                    }
                }
                
                completion(nil)
            } catch {
                print("급식 정보 파싱 오류: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    // 캐시 기능 추가
    private var mealCache: [String: MealInfo] = [:]
    
    public func getCachedMeal(date: Date, mealType: MealType) -> MealInfo? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let key = "\(dateFormatter.string(from: date))_\(mealType.rawValue)"
        return mealCache[key]
    }
    
    public func cacheMeal(date: Date, mealInfo: MealInfo) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let key = "\(dateFormatter.string(from: date))_\(mealInfo.mealType.rawValue)"
        mealCache[key] = mealInfo
    }
}
