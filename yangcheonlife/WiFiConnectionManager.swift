import SwiftUI
import NetworkExtension
import CoreLocation
import UIKit

// Wi-Fi 연결 클래스를 메인 코드에 통합하기 위한 클래스
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
    
    func connectToTestWiFi(completion: @escaping (Bool, String) -> Void) {
        let ssid = "WIFI_2.4Ghz"
        let password = "dngus11!"
        
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

struct WiFiConnectionView: View, CLLocationManagerDelegate {
    @State private var selectedGrade: Int = UserDefaults.standard.integer(forKey: "defaultGrade")
    @State private var selectedClass: Int = 1
    @State private var isConnecting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showTestOption: Bool = false
    @State private var locationPermissionGranted: Bool = false
    private let locationManager = CLLocationManager()
    
    init() {
        // CLLocationManagerDelegate 설정
        _locationManager.wrappedValue.delegate = self
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("학년 선택")) {
                    Picker("학년", selection: $selectedGrade) {
                        Text("1학년").tag(1)
                        Text("2학년").tag(2)
                        Text("3학년").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("반 선택")) {
                    if selectedGrade == 3 && showTestOption {
                        HStack {
                            Text("TEST")
                            Spacer()
                            Button(action: {
                                connectToTestWiFi()
                            }) {
                                Text("연결")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
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
                
                Section(header: Text("설정")) {
                    Toggle("TEST 옵션 표시", isOn: $showTestOption)
                        .onChange(of: showTestOption) { value in
                            UserDefaults.standard.set(value, forKey: "showWiFiTestOption")
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
            .navigationBarTitle("학교 Wi-Fi 연결", displayMode: .inline)
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
        .onAppear {
            showTestOption = UserDefaults.standard.bool(forKey: "showWiFiTestOption")
            checkLocationPermission()
        }
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
    
    private func connectToTestWiFi() {
        isConnecting = true
        
        WiFiConnectionManager.shared.connectToTestWiFi() { success, message in
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
    
    private func checkLocationPermission() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            locationPermissionGranted = true
        default:
            locationPermissionGranted = false
            // iOS 14부터는 위치 권한이 Wi-Fi 연결에 필요
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // CLLocationManagerDelegate 메서드
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationPermission()
    }
}

struct WiFiConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        WiFiConnectionView()
    }
}