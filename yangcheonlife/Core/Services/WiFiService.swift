import Foundation
import NetworkExtension
import CoreLocation

// MARK: - WiFi 연결 서비스
/// WiFi 연결 관리를 담당하는 서비스
class WiFiService: NSObject, ObservableObject {
    
    static let shared = WiFiService()
    
    // MARK: - Published Properties
    @Published var isConnecting = false
    @Published var lastConnectionResult: WiFiConnectionResult?
    @Published var hasLocationPermission = false
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        setupLocationManager()
        checkLocationPermission()
    }
    
    // MARK: - Public Methods
    
    /// 일반 교실 WiFi 연결
    func connectToClassroom(grade: Int, classNumber: Int) async -> WiFiConnectionResult {
        let connectionType = WiFiConnectionType.regularClassroom(grade: grade, classNumber: classNumber)
        return await connectToWiFi(type: connectionType)
    }
    
    /// 특별실 WiFi 연결
    func connectToSpecialRoom(_ room: SpecialRoomWiFi) async -> WiFiConnectionResult {
        let connectionType = WiFiConnectionType.specialRoom(room)
        return await connectToWiFi(type: connectionType)
    }
    
    /// 교실 번호 기반 WiFi 연결
    func connectToRoomNumber(grade: Int, classNumber: Int) async -> WiFiConnectionResult {
        let connectionType = WiFiConnectionType.roomNumber(grade: grade, classNumber: classNumber)
        return await connectToWiFi(type: connectionType)
    }
    
    /// 현재 수업 기반 WiFi 연결 제안
    func getSuggestedWiFiConnection(for scheduleItem: ScheduleItem) -> WiFiConnectionType? {
        // 정보 수업은 WiFi 제안하지 않음
        if scheduleItem.subject.contains("정보") {
            return nil
        }
        
        let classroom = scheduleItem.classroom.trimmingCharacters(in: .whitespaces)
        
        // 특별실인지 확인
        if SpecialRoomsData.isSpecialRoom(classroom) {
            if let specialRoom = SpecialRoomsData.findRoom(by: classroom) {
                return .specialRoom(specialRoom)
            }
        }
        
        // 교실 번호 확인 (3자리 숫자)
        if classroom.count == 3, let roomNumber = Int(classroom) {
            let grade = roomNumber / 100
            let classNum = roomNumber % 100
            
            if AppConstants.School.grades.contains(grade) && AppConstants.School.classes.contains(classNum) {
                return .roomNumber(grade: grade, classNumber: classNum)
            }
        }
        
        // 기본 교실 (현재 학년-반)
        if classroom.contains("T") || classroom.isEmpty {
            return .regularClassroom(grade: scheduleItem.grade, classNumber: scheduleItem.classNumber)
        }
        
        // 1, 2학년 특정 과목 특별 처리
        if scheduleItem.grade <= 2 {
            if scheduleItem.subject.contains("미술") {
                return .specialRoom(SpecialRoomsData.findRoom(by: "미술실")!)
            } else if scheduleItem.subject.contains("음악") {
                return .specialRoom(SpecialRoomsData.findRoom(by: "음악실")!)
            } else if scheduleItem.subject.contains("창독") {
                return .specialRoom(SpecialRoomsData.findRoom(by: "도서실")!)
            }
        }
        
        return nil
    }
    
    /// 위치 권한 요청
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Private Methods
    
    /// WiFi 연결 실행
    private func connectToWiFi(type: WiFiConnectionType) async -> WiFiConnectionResult {
        await MainActor.run {
            isConnecting = true
        }
        
        defer {
            Task { @MainActor in
                isConnecting = false
            }
        }
        
        // 위치 권한 확인
        guard hasLocationPermission else {
            let result = WiFiConnectionResult(
                isSuccess: false,
                message: "WiFi 연결을 위해 위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.",
                connectionType: type
            )
            
            await MainActor.run {
                lastConnectionResult = result
            }
            
            return result
        }
        
        return await withCheckedContinuation { continuation in
            let configuration = NEHotspotConfiguration(
                ssid: type.ssid,
                passphrase: type.password,
                isWEP: false
            )
            configuration.joinOnce = false
            configuration.hidden = true
            
            NEHotspotConfigurationManager.shared.apply(configuration) { error in
                let result: WiFiConnectionResult
                
                if let error = error {
                    if error.localizedDescription.contains("already associated") {
                        result = WiFiConnectionResult(
                            isSuccess: true,
                            message: "이미 \(type.displayName) WiFi에 연결되어 있습니다.",
                            connectionType: type
                        )
                    } else {
                        result = WiFiConnectionResult(
                            isSuccess: false,
                            message: "WiFi 연결 중 오류가 발생했습니다: \(error.localizedDescription)",
                            connectionType: type
                        )
                    }
                } else {
                    result = WiFiConnectionResult(
                        isSuccess: true,
                        message: "\(type.displayName) WiFi에 성공적으로 연결되었습니다.",
                        connectionType: type
                    )
                }
                
                Task { @MainActor in
                    self.lastConnectionResult = result
                }
                
                continuation.resume(returning: result)
            }
        }
    }
    
    /// 위치 관리자 설정
    private func setupLocationManager() {
        locationManager.delegate = self
    }
    
    /// 위치 권한 확인
    private func checkLocationPermission() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            hasLocationPermission = true
        default:
            hasLocationPermission = false
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension WiFiService: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationPermission()
    }
}