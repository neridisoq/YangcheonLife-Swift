import SwiftUI

// MARK: - View 확장
extension View {
    
    /// 조건부 뷰 모디파이어
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 옵셔널 값이 있을 때만 뷰 모디파이어 적용
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
    
    /// 앱 스타일 카드 효과
    func cardStyle(
        backgroundColor: Color = Color(UIColor.systemBackground),
        cornerRadius: CGFloat = AppConstants.UI.cornerRadius,
        shadowRadius: CGFloat = 5
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(radius: shadowRadius)
    }
    
    /// 앱 스타일 패딩
    func appPadding(_ edges: Edge.Set = .all) -> some View {
        self.padding(edges, AppConstants.UI.defaultPadding)
    }
    
    /// 작은 패딩
    func smallPadding(_ edges: Edge.Set = .all) -> some View {
        self.padding(edges, AppConstants.UI.smallPadding)
    }
    
    /// 로딩 오버레이
    func loadingOverlay(isLoading: Bool, message: String = "로딩 중...") -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text(message)
                                .foregroundColor(.white)
                                .font(.body)
                        }
                        .padding(24)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(AppConstants.UI.cornerRadius)
                        .shadow(radius: 10)
                    }
                }
            }
        )
    }
    
    /// 에러 얼럿
    func errorAlert(
        isPresented: Binding<Bool>,
        error: Error?,
        title: String = "오류"
    ) -> some View {
        self.alert(title, isPresented: isPresented) {
            Button("확인", role: .cancel) { }
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        }
    }
    
    /// 성공 얼럿
    func successAlert(
        isPresented: Binding<Bool>,
        message: String,
        title: String = "성공"
    ) -> some View {
        self.alert(title, isPresented: isPresented) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(message)
        }
    }
    
    /// 확인 얼럿
    func confirmationAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "확인",
        cancelTitle: String = "취소",
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.alert(title, isPresented: isPresented) {
            Button(confirmTitle, role: .destructive) {
                onConfirm()
            }
            Button(cancelTitle, role: .cancel) { }
        } message: {
            Text(message)
        }
    }
    
    /// 현재 교시 강조 스타일
    func currentPeriodStyle(isCurrentPeriod: Bool) -> some View {
        Group {
            if #available(iOS 16.0, *) {
                self
                    .background(isCurrentPeriod ? Color.currentPeriodBackground : Color.clear)
                    .fontWeight(isCurrentPeriod ? .bold : .regular)
                    .foregroundColor(isCurrentPeriod ? .primary : .primary)
            } else {
                self
                    .background(isCurrentPeriod ? Color.currentPeriodBackground : Color.clear)
                    .font(isCurrentPeriod ? .body.bold() : .body)
                    .foregroundColor(isCurrentPeriod ? .primary : .primary)
            }
        }
    }
    
    /// 테두리 스타일
    func borderStyle(
        color: Color = .primary,
        width: CGFloat = 1,
        cornerRadius: CGFloat = AppConstants.UI.cornerRadius
    ) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: width)
            )
    }
    
    /// 탭 가능한 스타일
    func tappableStyle() -> some View {
        self
            .contentShape(Rectangle())
            .hoverEffect(.lift)
    }
    
    /// 네비게이션 타이틀 설정 (iOS 버전별 호환성)
    func customNavigationTitle(_ title: String, displayMode: NavigationBarItem.TitleDisplayMode = .automatic) -> some View {
        if #available(iOS 14.0, *) {
            return AnyView(self.navigationTitle(title)
                .navigationBarTitleDisplayMode(displayMode))
        } else {
            return AnyView(self.navigationBarTitle(title, displayMode: displayMode))
        }
    }
    
    /// 키보드 해제 제스처 (메인 앱에서만 사용 가능)
    func dismissKeyboardOnTap() -> some View {
        self
        // 위젯 확장에서는 UIApplication.shared 사용 불가하므로 제거
        // 메인 앱에서만 별도로 구현 필요
    }
}

// MARK: - Text 확장
extension Text {
    
    /// 앱 스타일 헤더 텍스트
    func headerStyle() -> some View {
        self
            .font(.system(size: AppConstants.UI.headerFontSize, weight: .bold))
            .foregroundColor(.primary)
    }
    
    /// 앱 스타일 바디 텍스트
    func bodyStyle() -> some View {
        self
            .font(.system(size: AppConstants.UI.bodyFontSize))
            .foregroundColor(.primary)
    }
    
    /// 앱 스타일 캡션 텍스트
    func captionStyle() -> some View {
        self
            .font(.system(size: AppConstants.UI.captionFontSize))
            .foregroundColor(.secondary)
    }
    
    /// 앱 스타일 작은 텍스트
    func smallStyle() -> some View {
        self
            .font(.system(size: AppConstants.UI.smallFontSize))
            .foregroundColor(.secondary)
    }
}

// MARK: - Button 확장
extension Button {
    
    /// 기본 앱 스타일 버튼
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.appPrimary)
            .cornerRadius(AppConstants.UI.cornerRadius)
    }
    
    /// 보조 앱 스타일 버튼
    func secondaryButtonStyle() -> some View {
        self
            .foregroundColor(.appPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                    .stroke(Color.appPrimary, lineWidth: 1)
            )
    }
    
    /// 위험 스타일 버튼
    func destructiveButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.errorColor)
            .cornerRadius(AppConstants.UI.cornerRadius)
    }
}