
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
                    Text("새 업데이트 - 버전 3.2")
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
                            
                            // 기능 1: 알림 개선
                            VStack(alignment: .leading, spacing: 8) {
                                Text("1. 알림 시스템 개선")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Text("알림 시스템이 개선되어 더 안정적인 알림 서비스를 제공합니다. 이전 알림 시스템에서 발생할 수 있었던 중복 알림 문제가 해결되었습니다.")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                            
                            // 기능 2: 잠금화면 위젯
                            VStack(alignment: .leading, spacing: 8) {
                                Text("2. 잠금화면 위젯")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Text("iOS 16 이상에서 잠금화면에 위젯을 추가할 수 있습니다. 다음 수업, 체육 수업 정보를 잠금화면에서 바로 확인하세요.")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
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
                                
                                Text("학교에서 와이파이를 설정 -> 학교 Wi-Fi 연결을 통해 반별로 빠르고 편리하게 연결할 수 있습니다.")
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
