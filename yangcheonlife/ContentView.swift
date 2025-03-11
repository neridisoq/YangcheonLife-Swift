import SwiftUI

struct ContentView: View {
    @State private var showInitialSetup = !UserDefaults.standard.bool(forKey: "initialSetupCompleted")
    @ObservedObject private var updateService = AppUpdateService.shared
    
    // 업데이트 안내 표시 여부를 제어하는 상태 변수 추가
    @State private var showUpdateAnnouncement = false
    
    var body: some View {
        ZStack {
            Group {
                if updateService.updateRequired {
                    // 새 버전이 사용 가능한 경우 업데이트 필요 뷰 표시
                    UpdateRequiredView()
                } else if showInitialSetup {
                    InitialSetupView(showInitialSetup: $showInitialSetup)
                } else {
                    MainView() // 메인 화면 뷰
                }
            }
            
            // 업데이트 안내 조건부 표시
            if showUpdateAnnouncement {
                UpdateAnnouncementView(showUpdateAnnouncement: $showUpdateAnnouncement)
                    .transition(.opacity)
                    .zIndex(100) // 다른 모든 요소 위에 표시되도록 함
            }
        }
        .onAppear {
            // 앱이 나타날 때 업데이트 확인
            updateService.checkForUpdates()
            
            // 업데이트 안내를 표시해야 하는지 확인
            checkForVersionAnnouncement()
        }
    }
    
    // 업데이트 안내를 표시해야 하는지 확인하는 메서드
    private func checkForVersionAnnouncement() {
        // 현재 버전과 사용자가 확인한 최신 버전 가져오기
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let lastSeenVersion = UserDefaults.standard.string(forKey: "lastSeenUpdateVersion") ?? ""
        
        // 현재 버전이 "3.1"이고, 마지막으로 확인한 버전이 "3.1"이 아닌 경우에만 표시
        if currentVersion == "3.2" && lastSeenVersion != "3.1" && lastSeenVersion != "3.2" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showUpdateAnnouncement = true
                }
            }
        }
    }
}

struct UpdateAnnouncementView: View {
    @Binding var showUpdateAnnouncement: Bool
    @State private var hasScrolledToBottom = false
    
    var body: some View {
        ZStack {
            // 불투명한 배경
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // 메인 컨텐츠 카드
            VStack(spacing: 0) {
                // 헤더
                VStack(alignment: .leading, spacing: 4) {
                    Text("새 업데이트 - 버전 3.1")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("양천고라이프 앱이 업데이트 되었습니다!")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    ScrollViewReader { scrollProxy in
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("새로운 기능")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.white)
                                    .cornerRadius(4)
                                
                                Spacer()
                                
                                if !hasScrolledToBottom {
                                    Text("아래로 스크롤하여 모든 내용을 확인하세요")
                                        .font(.caption)
                                        .foregroundColor(.black)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.yellow)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.top, 6)
                            
                            // 기능 1: 잠금화면 위젯
                            VStack(alignment: .leading, spacing: 8) {
                                Text("1. 잠금화면 위젯")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Text("iOS 16 이상에서 잠금화면에 위젯을 추가할 수 있습니다. 다음 수업, 체육 수업 정보를 잠금화면에서 바로 확인하세요.")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                
                                // 스크린샷 - 실제 이미지
                                Image("lockscreen_widget_screenshot")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 180)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                            
                            // 기능 2: 일반 위젯
                            VStack(alignment: .leading, spacing: 8) {
                                Text("2. 일반 위젯")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Text("홈 화면에 추가할 수 있는 위젯이 개선되었습니다. 다음 수업, 체육 수업 정보, 급식 정보를 위젯으로 한눈에 확인하세요.")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                
                                // 스크린샷 - 실제 이미지
                                Image("home_widget_screenshot")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 180)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                            
                            // 기능 3: 와이파이 연결
                            VStack(alignment: .leading, spacing: 8) {
                                Text("3. 학교 와이파이 연결")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Text("학교에서 와이파이를 설정 -> 학교 Wi-Fi 연결을 통해 반별로 빠르고 편리하게 연결할 수 있습니다. 이제 번거롭게 비밀번호를 입력할 필요가 없습니다.")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                
                                // 스크린샷 - 실제 이미지
                                Image("wifi_screenshot")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 180)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                            
                            // 추가 개선사항
                            VStack(alignment: .leading, spacing: 8) {
                                Text("더 많은 개선사항")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text("시간표 표시 성능 개선")
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text("메모리 사용량 최적화")
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text("UI 개선 및 안정성 향상")
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.black)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                            
                            // 맨 아래 스크롤 감지용 마커
                            Button(action: {
                                // 명시적 버튼을 추가하여 사용자가 스크롤을 완료했음을 표시
                                withAnimation {
                                    hasScrolledToBottom = true
                                }
                            }) {
                                Text("모든 내용을 확인했습니다")
                                    .font(.caption)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .foregroundColor(.white)
                                    .background(Color.green)
                                    .cornerRadius(20)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                            .id("bottomMarker")
                        }
                        .padding()
                        .background(Color.white.opacity(0.95))
                    }
                }
                .background(Color.white)
                
                // 확인 버튼 푸터
                VStack(spacing: 12) {
                    if !hasScrolledToBottom {
                        Text("내용 확인 후 하단의 버튼을 눌러주세요")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .cornerRadius(4)
                    }
                    
                    Button(action: {
                        if hasScrolledToBottom {
                            // 중요: 사용자가 확인한 최신 버전을 저장
                            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                            UserDefaults.standard.set(currentVersion, forKey: "lastSeenUpdateVersion")
                            
                            withAnimation {
                                showUpdateAnnouncement = false
                            }
                        }
                    }) {
                        Text("업데이트 내용 확인 완료")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(hasScrolledToBottom ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!hasScrolledToBottom)
                }
                .padding()
                .background(Color.white)
            }
            .frame(maxWidth: 500, maxHeight: 600)
            .cornerRadius(12)
            .padding()
        }
    }
}

struct MainView: View {
    var body: some View {
        TabView {
            TimeTableTab()
                .tabItem {
                    Label(NSLocalizedString("TimeTable", comment: ""), systemImage: "calendar")
                }
            LunchTab()
                .tabItem {
                    Label(NSLocalizedString("Meal", comment: ""), systemImage: "fork.knife")
                }
            SettingsTab()
                .tabItem {
                    Label(NSLocalizedString("Settings", comment: ""), systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
