//
//  UpdateRequiredView.swift
//  yangcheonlife
//
//  Created by Woohyun Jin on 3/4/25.
//


import SwiftUI

struct UpdateRequiredView: View {
    @ObservedObject private var updateService = AppUpdateService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.app")
                .font(.system(size: 70))
                .foregroundColor(.blue)
                .padding()
            
            Text("업데이트 필요")
                .font(.title)
                .fontWeight(.bold)
            
            Text("새로운 버전이 출시되었습니다.\n계속 사용하시려면 업데이트를 진행해주세요.")
                .multilineTextAlignment(.center)
                .padding()
            
            if let appVersion = updateService.appStoreVersion {
                Text("최신 버전: \(appVersion)")
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                updateService.openAppStore()
            }) {
                Text("지금 업데이트하기")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top)
        }
        .padding()
    }
}

struct UpdateRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateRequiredView()
    }
}