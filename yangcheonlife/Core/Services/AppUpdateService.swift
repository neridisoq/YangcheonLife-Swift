// AppUpdateService.swift - 앱 업데이트 서비스
import Foundation
import SwiftUI
import Combine

/// 앱 업데이트 확인 및 관리 서비스
class AppUpdateService: ObservableObject {
    
    static let shared = AppUpdateService()
    
    // MARK: - Published Properties
    @Published var updateRequired = false
    @Published var updateAvailable = false
    @Published var latestVersion = ""
    @Published var isChecking = false
    
    // MARK: - Private Properties
    private let currentVersion: String
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0"
    }
    
    // MARK: - Public Methods
    
    /// 업데이트 확인
    func checkForUpdates() {
        guard !isChecking else { return }
        
        isChecking = true
        
        // 앱스토어 API를 통한 실제 업데이트 확인
        checkAppStoreVersion()
    }
    
    /// 앱스토어로 이동 (메인 앱에서만 사용 가능)
    func openAppStore() {
        // 위젯 확장에서는 URL 열기 기능 사용 불가
        // 메인 앱에서는 별도로 구현 필요
        print("📱 앱스토어로 이동 요청 - 메인 앱에서만 지원")
    }
    
    // MARK: - Private Methods
    
    /// 앱스토어 API를 통한 버전 확인
    private func checkAppStoreVersion() {
        let appID = "6502401068" // 앱스토어 앱 ID
        let url = URL(string: "https://itunes.apple.com/lookup?id=\(appID)")!
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isChecking = false
            }
            
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("❌ 앱스토어 API 호출 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appInfo = results.first,
                   let storeVersion = appInfo["version"] as? String {
                    
                    DispatchQueue.main.async {
                        self.processVersionComparison(storeVersion: storeVersion)
                    }
                } else {
                    print("❌ 앱스토어 응답 파싱 실패")
                }
            } catch {
                print("❌ JSON 파싱 실패: \(error)")
            }
        }.resume()
    }
    
    /// 버전 비교 처리
    private func processVersionComparison(storeVersion: String) {
        latestVersion = storeVersion
        
        let currentVersionNumber = versionStringToNumber(currentVersion)
        let latestVersionNumber = versionStringToNumber(storeVersion)
        
        updateAvailable = latestVersionNumber > currentVersionNumber
        updateRequired = latestVersionNumber > currentVersionNumber
        
        print("📱 현재 버전: \(currentVersion) (\(currentVersionNumber))")
        print("📱 앱스토어 버전: \(storeVersion) (\(latestVersionNumber))")
        print("📱 업데이트 필요: \(updateRequired), 업데이트 가능: \(updateAvailable)")
    }
    
    /// 버전 문자열을 숫자로 변환 (개선된 버전)
    private func versionStringToNumber(_ version: String) -> Int {
        let components = version.components(separatedBy: ".")
        
        // 최대 3개의 구성요소만 처리 (major.minor.patch)
        var normalizedComponents: [Int] = []
        
        for i in 0..<3 {
            if i < components.count, let number = Int(components[i]) {
                normalizedComponents.append(number)
            } else {
                normalizedComponents.append(0) // 없는 부분은 0으로 처리
            }
        }
        
        // major * 10000 + minor * 100 + patch 형태로 계산
        return normalizedComponents[0] * 10000 + normalizedComponents[1] * 100 + normalizedComponents[2]
    }
}

// MARK: - 업데이트 필요 뷰
struct UpdateRequiredView: View {
    
    @ObservedObject private var updateService = AppUpdateService.shared
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.appPrimary)
            
            VStack(spacing: 16) {
                Text("업데이트가 필요합니다")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("새로운 기능과 개선사항을 위해\n최신 버전으로 업데이트해주세요.")
                    .bodyStyle()
                    .multilineTextAlignment(.center)
                
                if !updateService.latestVersion.isEmpty {
                    Text("최신 버전: \(updateService.latestVersion)")
                        .captionStyle()
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button("App Store에서 업데이트") {
                    updateService.openAppStore()
                }
                .primaryButtonStyle()
                
                Text("업데이트 후 다시 실행해주세요")
                    .captionStyle()
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .appPadding()
    }
}

// MARK: - 업데이트 안내 뷰
struct UpdateAnnouncementView: View {
    
    @Binding var showUpdateAnnouncement: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.appPrimary)
                
                VStack(spacing: 12) {
                    Text("양천고 라이프 4.1")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("새로운 기능과 개선사항")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    featureItem("최적화")
                    featureItem("라이브 액티비티")
                    featureItem("위젯 오류시 삭제후 다시 추가")
                }
                
                Button("확인") {
                    // 사용자가 업데이트 안내를 확인했음을 저장
                    UserDefaults.standard.set(AppConstants.App.version, forKey: AppConstants.UserDefaultsKeys.lastSeenUpdateVersion)
                    
                    withAnimation {
                        showUpdateAnnouncement = false
                    }
                }
                .primaryButtonStyle()
            }
            .padding(30)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(30)
        }
    }
    
    /// 기능 항목 뷰
    private func featureItem(_ text: String) -> some View {
        HStack(spacing: 12) {
            Text(text)
                .bodyStyle()
            
            Spacer()
        }
    }
}

// MARK: - 미리보기
struct UpdateViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UpdateRequiredView()
                .previewDisplayName("업데이트 필요")
            
            UpdateAnnouncementView(showUpdateAnnouncement: .constant(true))
                .previewDisplayName("업데이트 안내")
        }
    }
}
