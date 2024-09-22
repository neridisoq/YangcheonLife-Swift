import SwiftUI
import WebKit

struct LunchTab: View {
    @State private var isLoading: Bool = true

    var body: some View {
  //      NavigationView {
            ZStack {
                WebViewContainer(isLoading: $isLoading)
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5, anchor: .center)
                }
            }
            .navigationBarTitle(Text("급식"), displayMode: .inline)
            
        }//.navigationViewStyle(StackNavigationViewStyle())
  //  }
}

struct WebViewContainer: UIViewRepresentable {
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: "https://meal.dkqq.me") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewContainer

        init(_ parent: WebViewContainer) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

struct LunchTab_Previews: PreviewProvider {
    static var previews: some View {
        LunchTab()
    }
}

