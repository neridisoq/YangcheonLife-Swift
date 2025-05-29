import SwiftUI

// MARK: - 로딩 뷰 컴포넌트
struct LoadingView: View {
    let message: String
    let showBackground: Bool
    
    init(message: String = "로딩 중...", showBackground: Bool = true) {
        self.message = message
        self.showBackground = showBackground
    }
    
    var body: some View {
        ZStack {
            if showBackground {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                
                Text(message)
                    .foregroundColor(showBackground ? .white : .primary)
                    .font(.body)
            }
            .padding(24)
            .if(showBackground) { view in
                view
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(AppConstants.UI.cornerRadius)
                    .shadow(radius: 10)
            }
        }
    }
}

// MARK: - 에러 뷰 컴포넌트
struct ErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?
    
    init(error: Error, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.errorColor)
            
            Text("오류가 발생했습니다")
                .headerStyle()
            
            Text(error.localizedDescription)
                .bodyStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let retryAction = retryAction {
                Button("다시 시도") {
                    retryAction()
                }
                .primaryButtonStyle()
            }
        }
        .padding()
    }
}

// MARK: - 빈 상태 뷰 컴포넌트
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        systemImage: String = "doc.text",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .headerStyle()
                
                Text(message)
                    .captionStyle()
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    action()
                }
                .primaryButtonStyle()
            }
        }
        .padding()
    }
}

// MARK: - 성공 뷰 컴포넌트
struct SuccessView: View {
    let title: String
    let message: String
    let dismissAction: (() -> Void)?
    
    init(title: String = "성공!", message: String, dismissAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.successColor)
            
            Text(title)
                .headerStyle()
            
            Text(message)
                .bodyStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let dismissAction = dismissAction {
                Button("확인") {
                    dismissAction()
                }
                .primaryButtonStyle()
            }
        }
        .padding()
    }
}

// MARK: - 미리보기
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView()
                .previewDisplayName("Loading with Background")
            
            LoadingView(message: "데이터 로딩 중...", showBackground: false)
                .previewDisplayName("Loading without Background")
            
            ErrorView(error: NSError(domain: "TestError", code: 0, userInfo: [NSLocalizedDescriptionKey: "테스트 에러 메시지입니다."])) {
                print("Retry tapped")
            }
            .previewDisplayName("Error View")
            
            EmptyStateView(
                title: "시간표가 없습니다",
                message: "아직 불러온 시간표가 없습니다.\n새로고침을 눌러 시간표를 불러오세요.",
                systemImage: "calendar.badge.exclamationmark",
                actionTitle: "새로고침"
            ) {
                print("Refresh tapped")
            }
            .previewDisplayName("Empty State View")
            
            SuccessView(
                title: "연결 성공!",
                message: "WiFi에 성공적으로 연결되었습니다."
            ) {
                print("Dismiss tapped")
            }
            .previewDisplayName("Success View")
        }
    }
}