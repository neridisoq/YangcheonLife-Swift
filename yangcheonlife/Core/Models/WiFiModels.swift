import Foundation

// MARK: - WiFi 관련 모델들

/// 특별실 WiFi 정보 모델
struct SpecialRoomWiFi: Identifiable, Equatable {
    let id = UUID()
    let name: String        // 특별실 이름
    let ssid: String        // WiFi SSID
    let password: String    // WiFi 비밀번호
    
    init(name: String, ssid: String, password: String) {
        self.name = name
        self.ssid = ssid
        self.password = password
    }
}

/// WiFi 연결 유형 열거형
enum WiFiConnectionType {
    case regularClassroom(grade: Int, classNumber: Int)  // 일반 교실 (학년-반)
    case specialRoom(SpecialRoomWiFi)                    // 특별실
    case roomNumber(grade: Int, classNumber: Int)        // 교실 번호 기반
    
    /// 표시용 이름
    var displayName: String {
        switch self {
        case .regularClassroom(let grade, let classNumber):
            return "\(grade)학년 \(classNumber)반 교실"
        case .specialRoom(let room):
            return room.name
        case .roomNumber(let grade, let classNumber):
            return "\(grade)학년 \(classNumber)반 교실"
        }
    }
    
    /// SSID 생성
    var ssid: String {
        switch self {
        case .regularClassroom(let grade, let classNumber), .roomNumber(let grade, let classNumber):
            return "\(grade)-\(classNumber)"
        case .specialRoom(let room):
            return room.ssid
        }
    }
    
    /// 비밀번호 생성
    var password: String {
        switch self {
        case .regularClassroom(let grade, let classNumber), .roomNumber(let grade, let classNumber):
            let suffix = String(format: "%d%02d", grade, classNumber)
            return "yangcheon\(suffix)"
        case .specialRoom(let room):
            return room.password
        }
    }
}

/// WiFi 연결 결과 모델
struct WiFiConnectionResult {
    let isSuccess: Bool     // 연결 성공 여부
    let message: String     // 결과 메시지
    let connectionType: WiFiConnectionType // 연결 유형
    
    init(isSuccess: Bool, message: String, connectionType: WiFiConnectionType) {
        self.isSuccess = isSuccess
        self.message = message
        self.connectionType = connectionType
    }
}

/// 특별실 WiFi 데이터
struct SpecialRoomsData {
    /// 모든 특별실 WiFi 정보
    static let allRooms: [SpecialRoomWiFi] = [
        SpecialRoomWiFi(name: "화학생명실", ssid: "화학생명실", password: "yangcheon401"),
        SpecialRoomWiFi(name: "홈베이스A/B", ssid: "홈베이스", password: "yangcheon402"),
        SpecialRoomWiFi(name: "음악실", ssid: "음악실", password: "yangcheon403"),
        SpecialRoomWiFi(name: "소강당", ssid: "소강당", password: "yangcheon404"),
        SpecialRoomWiFi(name: "미술실", ssid: "미술실", password: "yangcheon405"),
        SpecialRoomWiFi(name: "물리지학실", ssid: "물리지학실", password: "yangcheon406"),
        SpecialRoomWiFi(name: "멀티스튜디오", ssid: "멀티스튜디오", password: "yangcheon407"),
        SpecialRoomWiFi(name: "다목적실A/B", ssid: "다목적실AB", password: "yangcheon408"),
        SpecialRoomWiFi(name: "꿈담카페A", ssid: "꿈담카페A", password: "yangcheon409"),
        SpecialRoomWiFi(name: "꿈담카페B", ssid: "꿈담카페B", password: "yangcheon410"),
        SpecialRoomWiFi(name: "도서실", ssid: "도서실", password: "yangcheon411"),
        SpecialRoomWiFi(name: "세미나실", ssid: "세미나실", password: "yangcheon412"),
        SpecialRoomWiFi(name: "상록실", ssid: "상록실", password: "yangcheon413"),
        SpecialRoomWiFi(name: "senWiFi_Free", ssid: "senWiFi_Free", password: "888884444g")
    ]
    
    /// 특별실 이름으로 WiFi 정보 찾기
    static func findRoom(by name: String) -> SpecialRoomWiFi? {
        // 정확한 이름으로 먼저 찾기
        if let exactMatch = allRooms.first(where: { $0.name == name }) {
            return exactMatch
        }
        
        // 부분 일치로 찾기 (홈베이스A, 다목적실B 등)
        return allRooms.first { room in
            name.contains(room.name.components(separatedBy: "/")[0]) ||
            room.name.contains(name)
        }
    }
    
    /// 교실명으로 특별실인지 확인
    static func isSpecialRoom(_ classroom: String) -> Bool {
        let trimmedName = classroom.trimmingCharacters(in: .whitespaces)
        
        // 일반 교실 번호 형식인지 확인 (3자리 숫자)
        if trimmedName.count == 3, Int(trimmedName) != nil {
            return false
        }
        
        // 'T'가 포함된 경우 일반 교실
        if trimmedName.contains("T") {
            return false
        }
        
        // 특별실 목록에 있는지 확인
        return findRoom(by: trimmedName) != nil
    }
}