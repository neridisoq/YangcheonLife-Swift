import SwiftUI
import NetworkExtension
import CoreLocation
import UIKit

// Wi-Fi 연결 관리 클래스
class WiFiConnectionManager {
    static let shared = WiFiConnectionManager()
    
    private init() {}
    
    func connectToWiFi(grade: Int, classNumber: Int, completion: @escaping (Bool, String) -> Void) {
        guard grade >= 1 && grade <= 3 && classNumber >= 1 && classNumber <= 11 else {
            completion(false, "유효하지 않은 학년 또는 반 번호입니다.")
            return
        }
        
        let ssid = "\(grade)-\(classNumber)"
        let passwordSuffix = String(format: "%d%02d", grade, classNumber)
        let password = "yangcheon\(passwordSuffix)"
        
        connectToWiFiNetwork(ssid: ssid, password: password, completion: completion)
    }
    
    func connectToSpecialRoomWiFi(ssid: String, password: String, completion: @escaping (Bool, String) -> Void) {
        connectToWiFiNetwork(ssid: ssid, password: password, completion: completion)
    }
    
    private func connectToWiFiNetwork(ssid: String, password: String, completion: @escaping (Bool, String) -> Void) {
        // Wi-Fi 연결 설정
        let configuration = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        configuration.joinOnce = false
        configuration.hidden = true
        
        NEHotspotConfigurationManager.shared.apply(configuration) { error in
            DispatchQueue.main.async {
                if let error = error {
                    if error.localizedDescription.contains("already associated") {
                        // 이미 연결된 경우
                        completion(true, "이미 \(ssid) 네트워크에 연결되어 있습니다.")
                    } else {
                        // 연결 오류
                        completion(false, "연결 중 오류가 발생했습니다: \(error.localizedDescription)")
                    }
                } else {
                    // 연결 성공
                    completion(true, "\(ssid) 네트워크에 연결되었습니다.")
                }
            }
        }
    }
}

// 위치 권한 관리 클래스
class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()
    
    private let locationManager = CLLocationManager()
    var permissionGranted: Bool = false
    var onPermissionChange: ((Bool) -> Void)?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        checkPermission()
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func checkPermission() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            permissionGranted = true
        default:
            permissionGranted = false
        }
        onPermissionChange?(permissionGranted)
    }
    
    // CLLocationManagerDelegate 메서드
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkPermission()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkPermission()
    }
}

// 특별실 Wi-Fi 정보 구조체
struct SpecialRoomWiFi: Identifiable {
    let id = UUID()
    let name: String
    let ssid: String
    let password: String
}

// Wi-Fi 연결 뷰
struct WiFiConnectionView: View {
    @State private var selectedGrade: Int = UserDefaults.standard.integer(forKey: "defaultGrade")
    @State private var selectedClass: Int = UserDefaults.standard.integer(forKey: "defaultClass")
    @State private var isConnecting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var locationPermissionGranted: Bool = false
    
    // 특별실 Wi-Fi 목록
    let specialRooms: [SpecialRoomWiFi] = [
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
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("학년 선택")) {
                    Picker("학년", selection: $selectedGrade) {
                        ForEach(1..<4) { grade in
                            Text("\(grade)학년").tag(grade)
                        }
                        Text("특별실").tag(4)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("반 선택")) {
                    if selectedGrade == 4 {
                        // 특별실 Wi-Fi 목록
                        ForEach(specialRooms) { room in
                            HStack {
                                Text(room.name)
                                Spacer()
                                Button(action: {
                                    connectToSpecialRoom(ssid: room.ssid, password: room.password)
                                }) {
                                    Text("연결")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    } else {
                        // 일반 교실 Wi-Fi 목록
                        ForEach(1..<12) { classNumber in
                            HStack {
                                Text("\(classNumber)반")
                                Spacer()
                                Button(action: {
                                    connectToWiFi(grade: selectedGrade, classNumber: classNumber)
                                }) {
                                    Text("연결")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("안내")) {
                    if !locationPermissionGranted {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Wi-Fi 연결을 위해 위치 권한이 필요합니다.")
                                .font(.footnote)
                            Spacer()
                            Button("설정") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.footnote)
                        }
                    }
                    
                    Text("• 학교 Wi-Fi는 SSID가 숨김 설정되어 있습니다.")
                        .font(.footnote)
                    Text("• 연결이 안 될 경우 위치 서비스와 Wi-Fi 권한을 확인해주세요.")
                        .font(.footnote)
                    Text("• 학년-반 형식으로 SSID가 설정되어 있습니다. (예: 3-5)")
                        .font(.footnote)
                    Text("• 비밀번호는 'yangcheon' + 학년 + 반 번호 형식입니다.")
                        .font(.footnote)
                    Text("• 예: 3학년 5반 → SSID: 3-5, 비밀번호: yangcheon305")
                        .font(.footnote)
                }
            }
            .navigationBarTitle("학교 Wi-Fi 연결")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인"))
                )
            }
            .overlay(
                Group {
                    if isConnecting {
                        ZStack {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                                Text("Wi-Fi 연결 중...")
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                        }
                    }
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadSettings()
            
            // 위치 권한 확인 및 설정
            locationPermissionGranted = LocationPermissionManager.shared.permissionGranted
            LocationPermissionManager.shared.onPermissionChange = { granted in
                self.locationPermissionGranted = granted
            }
            
            // 권한이 없는 경우 요청
            if !locationPermissionGranted {
                LocationPermissionManager.shared.requestPermission()
            }
        }
    }
    
    private func loadSettings() {
        selectedGrade = UserDefaults.standard.integer(forKey: "defaultGrade")
        selectedClass = UserDefaults.standard.integer(forKey: "defaultClass")
    }
    
    private func connectToWiFi(grade: Int, classNumber: Int) {
        isConnecting = true
        
        WiFiConnectionManager.shared.connectToWiFi(grade: grade, classNumber: classNumber) { success, message in
            isConnecting = false
            
            if success {
                self.alertTitle = "연결 성공"
                self.alertMessage = message
            } else {
                self.alertTitle = "연결 오류"
                self.alertMessage = message
            }
            
            self.showAlert = true
        }
    }
    
    private func connectToSpecialRoom(ssid: String, password: String) {
        isConnecting = true
        
        WiFiConnectionManager.shared.connectToSpecialRoomWiFi(ssid: ssid, password: password) { success, message in
            isConnecting = false
            
            if success {
                self.alertTitle = "연결 성공"
                self.alertMessage = message
            } else {
                self.alertTitle = "연결 오류"
                self.alertMessage = message
            }
            
            self.showAlert = true
        }
    }
    
    private func showConnectionError(message: String) {
        alertTitle = "연결 오류"
        alertMessage = message
        showAlert = true
    }
}

struct WiFiConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        WiFiConnectionView()
    }
}
