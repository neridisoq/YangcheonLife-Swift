//
//  AppUpdateService.swift
//  yangcheonlife
//
//  Created by Woohyun Jin on 3/4/25.
//


import Foundation
import SwiftUI

class AppUpdateService: ObservableObject {
    static let shared = AppUpdateService()
    
    @Published var updateRequired = false
    @Published var appStoreVersion: String?
    
    private let appId = "6502401068"
    // Replace with your App Store app ID
    
    private init() {}
    
    func checkForUpdates() {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            print("Could not get current app version")
            return
        }
        
        // Fetch the latest version from App Store
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(appId)") else {
            print("Invalid App Store URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                print("Failed to fetch App Store data")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appStoreInfo = results.first,
                   let latestVersion = appStoreInfo["version"] as? String {
                    
                    DispatchQueue.main.async {
                        self.appStoreVersion = latestVersion
                        
                        // Compare versions
                        self.updateRequired = self.compareVersions(currentVersion, latestVersion)
                        print("Current version: \(currentVersion), App Store version: \(latestVersion), Update required: \(self.updateRequired)")
                    }
                }
            } catch {
                print("Error parsing App Store JSON: \(error)")
            }
        }.resume()
    }
    
    // Compare version strings and return true if app store version is newer
    private func compareVersions(_ current: String, _ appStore: String) -> Bool {
        let currentComponents = current.components(separatedBy: ".").compactMap { Int($0) }
        let appStoreComponents = appStore.components(separatedBy: ".").compactMap { Int($0) }
        
        // Make arrays same length by padding with zeros
        let currentPadded = currentComponents + Array(repeating: 0, count: max(0, appStoreComponents.count - currentComponents.count))
        let appStorePadded = appStoreComponents + Array(repeating: 0, count: max(0, currentComponents.count - appStoreComponents.count))
        
        // Compare each component
        for (current, appStore) in zip(currentPadded, appStorePadded) {
            if appStore > current {
                return true
            } else if current > appStore {
                return false
            }
        }
        
        return false // Versions are equal, no update required
    }
    
    func openAppStore() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
