// WiFiConnectionView.swift - WiFi 연결 뷰
import SwiftUI

struct WiFiConnectionView: View {
    
    // MARK: - State Properties
    @StateObject private var wifiService = WiFiService.shared
    @State private var selectedGrade = 3
    @State private var selectedClassNumber = 5
    @State private var selectedRoomType = 0 // 0: 일반교실, 1: 특별실
    @State private var connectionResult: WiFiConnectionResult?
    @State private var showResult = false
    
    // MARK: - Private Properties
    private let specialRooms = SpecialRoomsData.allRooms
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                // 연결 유형 선택
                connectionTypeSection
                
                // 일반 교실 선택
                if selectedRoomType == 0 {
                    regularClassroomSection
                }
                
                // 특별실 선택
                if selectedRoomType == 1 {
                    specialRoomSection
                }
                
                // 안내사항
                infoSection
            }
            .navigationTitle("학교 WiFi 연결")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadDefaultSettings()
            }
            .loadingOverlay(isLoading: wifiService.isConnecting)
            .alert("WiFi 연결 결과", isPresented: $showResult) {
                Button("확인", role: .cancel) { }
            } message: {
                if let result = connectionResult {
                    Text(result.message)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - View Sections
    
    /// 연결 유형 선택 섹션
    private var connectionTypeSection: some View {
        Section("연결 유형") {
            Picker("유형", selection: $selectedRoomType) {
                Text("일반 교실").tag(0)
                Text("특별실").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    /// 일반 교실 섹션
    private var regularClassroomSection: some View {
        Section("일반 교실 WiFi") {
            // 학년 선택
            Picker("학년", selection: $selectedGrade) {
                ForEach(AppConstants.School.grades, id: \.self) { grade in
                    Text("\(grade)학년").tag(grade)
                }
            }
            
            // 반 선택
            Picker("반", selection: $selectedClassNumber) {
                ForEach(AppConstants.School.classes, id: \.self) { classNumber in
                    Text("\(classNumber)반").tag(classNumber)
                }
            }
            
            // 연결 버튼
            Button("🔗 \(selectedGrade)학년 \(selectedClassNumber)반 WiFi 연결") {
                connectToClassroom()
            }
            .primaryButtonStyle()
            .disabled(wifiService.isConnecting)
        }
    }
    
    /// 특별실 섹션
    private var specialRoomSection: some View {
        Section("특별실 WiFi") {
            ForEach(specialRooms) { room in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(room.name)
                            .bodyStyle()
                        
                        Text("SSID: \(room.ssid)")
                            .captionStyle()
                    }
                    
                    Spacer()
                    
                    Button("연결") {
                        connectToSpecialRoom(room)
                    }
                    .secondaryButtonStyle()
                    .disabled(wifiService.isConnecting)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    /// 안내사항 섹션
    private var infoSection: some View {
        Section("안내사항") {
            if !wifiService.hasLocationPermission {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.warningColor)
                    
                    VStack(alignment: .leading) {
                        Text("위치 권한 필요")
                            .bodyStyle()
                        Text("WiFi 연결을 위해 위치 권한이 필요합니다.")
                            .captionStyle()
                    }
                    
                    Spacer()
                    
                    Button("설정") {
                        openSettings()
                    }
                    .secondaryButtonStyle()
                }
            }
            
            Text("• 학교 WiFi는 SSID가 숨김 설정되어 있습니다.")
                .captionStyle()
            
            Text("• 일반교실 SSID 형식: 학년-반 (예: 3-5)")
                .captionStyle()
            
            Text("• 일반교실 비밀번호 형식: yangcheon + 학년반번호")
                .captionStyle()
            
            Text("• 예시: 3학년 5반 → SSID: 3-5, 비밀번호: yangcheon305")
                .captionStyle()
        }
    }
    
    // MARK: - Private Methods
    
    /// 기본 설정 로드
    private func loadDefaultSettings() {
        selectedGrade = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        selectedClassNumber = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
        
        if selectedGrade == 0 { selectedGrade = 3 }
        if selectedClassNumber == 0 { selectedClassNumber = 5 }
    }
    
    /// 일반 교실 WiFi 연결
    private func connectToClassroom() {
        Task {
            let result = await wifiService.connectToClassroom(
                grade: selectedGrade,
                classNumber: selectedClassNumber
            )
            
            await MainActor.run {
                connectionResult = result
                showResult = true
            }
        }
    }
    
    /// 특별실 WiFi 연결
    private func connectToSpecialRoom(_ room: SpecialRoomWiFi) {
        Task {
            let result = await wifiService.connectToSpecialRoom(room)
            
            await MainActor.run {
                connectionResult = result
                showResult = true
            }
        }
    }
    
    /// 설정 앱 열기
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - 미리보기
struct WiFiConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        WiFiConnectionView()
            .previewDisplayName("WiFi 연결")
    }
}