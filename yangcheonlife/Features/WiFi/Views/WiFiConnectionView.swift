// WiFiConnectionView.swift - WiFi 연결 뷰
import SwiftUI

struct WiFiConnectionView: View {
    
    // MARK: - State Properties
    @StateObject private var wifiService = WiFiService.shared
    @State private var selectedGrade = 3
    @State private var selectedClassNumber = 5
    @State private var selectedTab = 2 // 0: 1학년, 1: 2학년, 2: 3학년, 3: 특별실
    @State private var connectionResult: WiFiConnectionResult?
    @State private var showResult = false
    
    // MARK: - Private Properties
    private let specialRooms = SpecialRoomsData.allRooms
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상단 탭 선택
                gradeTabSection
                
                // 하단 컨텐츠
                TabView(selection: $selectedTab) {
                    // 1학년 탭
                    gradeClassroomView(grade: 1)
                        .tag(0)
                    
                    // 2학년 탭
                    gradeClassroomView(grade: 2)
                        .tag(1)
                    
                    // 3학년 탭
                    gradeClassroomView(grade: 3)
                        .tag(2)
                    
                    // 특별실 탭
                    specialRoomView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
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
    
    /// 학년 탭 선택 섹션
    private var gradeTabSection: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                } label: {
                    Text(tabTitle(for: index))
                        .font(.system(size: 15, weight: selectedTab == index ? .medium : .regular))
                        .foregroundColor(selectedTab == index ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedTab == index ? Color.blue.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    /// 학년별 교실 뷰
    private func gradeClassroomView(grade: Int) -> some View {
        VStack(spacing: 0) {
            List {
                Section("\(grade)학년 교실 WiFi") {
                    ForEach(AppConstants.School.classes, id: \.self) { classNumber in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(grade)학년 \(classNumber)반")
                                    .bodyStyle()
                                
                                Text("SSID: \(grade)-\(classNumber)")
                                    .captionStyle()
                            }
                            
                            Spacer()
                            
                            Button("연결") {
                                selectedGrade = grade
                                selectedClassNumber = classNumber
                                connectToClassroom()
                            }
                            .secondaryButtonStyle()
                            .disabled(wifiService.isConnecting)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // 안내사항 (각 탭에 표시)
                gradeInfoSection(grade: grade)
            }
        }
    }
    
    /// 특별실 뷰
    private var specialRoomView: some View {
        List {
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
            
            // 특별실 안내사항
            specialRoomInfoSection
        }
    }
    
    /// 학년별 안내사항 섹션
    private func gradeInfoSection(grade: Int) -> some View {
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
            
            Text("• \(grade)학년 SSID 형식: \(grade)-반번호 (예: \(grade)-5)")
                .captionStyle()
            
            Text("• 비밀번호 형식: yangcheon + 학년반번호")
                .captionStyle()
            
            Text("• 예시: \(grade)학년 5반 → SSID: \(grade)-5, 비밀번호: yangcheon\(grade)05")
                .captionStyle()
        }
    }
    
    /// 특별실 안내사항 섹션
    private var specialRoomInfoSection: some View {
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
            
            Text("• 특별실은 고유한 SSID와 비밀번호를 가집니다.")
                .captionStyle()
            
            Text("• 각 특별실의 SSID와 비밀번호는 위 목록을 참고하세요.")
                .captionStyle()
        }
    }
    
    // MARK: - Private Methods
    
    /// 탭 제목 반환
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "1학년"
        case 1: return "2학년"
        case 2: return "3학년"
        case 3: return "특별실"
        default: return ""
        }
    }
    
    /// 기본 설정 로드
    private func loadDefaultSettings() {
        selectedGrade = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        selectedClassNumber = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.defaultClass)
        
        if selectedGrade == 0 { selectedGrade = 3 }
        if selectedClassNumber == 0 { selectedClassNumber = 5 }
        
        // 저장된 학년에 따라 기본 탭 설정
        selectedTab = selectedGrade - 1
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