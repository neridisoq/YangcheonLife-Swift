// MealTabView.swift - 급식 탭 뷰
import SwiftUI
import WebKit

struct MealTabView: View {
    
    // MARK: - State Properties
    @State private var isLoading = true
    @State private var hasError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 웹뷰 컨테이너
            MealWebView(
                isLoading: $isLoading,
                hasError: $hasError,
                errorMessage: $errorMessage
            )
            
            // 로딩 인디케이터
            if isLoading {
                LoadingView(message: NSLocalizedString(LocalizationKeys.loadingMealInfo, comment: ""), showBackground: false)
            }
            
            // 에러 상태
            if hasError {
                ErrorView(error: MealError.loadFailed(errorMessage)) {
                    reloadMealInfo()
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .onAppear {
            updateLiveActivityOnTabLoad()
        }
    }
    
    // MARK: - Private Methods
    
    /// 급식 정보 새로고침
    private func reloadMealInfo() {
        hasError = false
        isLoading = true
        
        // WebView 새로고침은 MealWebView에서 처리
    }
    
    /// 탭 로드시 라이브 액티비티 업데이트
    private func updateLiveActivityOnTabLoad() {
        if #available(iOS 18.0, *) {
            LiveActivityManager.shared.updateLiveActivity()
        }
    }
}

// MARK: - 급식 웹뷰 컨테이너
struct MealWebView: UIViewRepresentable {
    
    // MARK: - Bindings
    @Binding var isLoading: Bool
    @Binding var hasError: Bool
    @Binding var errorMessage: String
    
    // MARK: - UIViewRepresentable
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.scrollView.isScrollEnabled = true
        
        // 급식 페이지 로드
        if let url = URL(string: AppConstants.API.mealURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            hasError = true
            errorMessage = NSLocalizedString(LocalizationKeys.invalidMealURL, comment: "")
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 새로고침이 필요한 경우
        if hasError {
            webView.reload()
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: MealWebView
        
        init(_ parent: MealWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.hasError = false
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.hasError = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.hasError = true
                self.parent.errorMessage = error.localizedDescription
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.hasError = true
                self.parent.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 급식 에러 타입
enum MealError: LocalizedError {
    case loadFailed(String)
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return String(format: NSLocalizedString(LocalizationKeys.mealLoadingFailed, comment: ""), message)
        case .invalidURL:
            return NSLocalizedString(LocalizationKeys.invalidMealURL, comment: "")
        }
    }
}

// MARK: - 미리보기
struct MealTabView_Previews: PreviewProvider {
    static var previews: some View {
        MealTabView()
            .previewDisplayName("급식 탭")
    }
}