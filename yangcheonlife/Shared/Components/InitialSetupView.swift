// InitialSetupView.swift - 초기 설정 뷰
import SwiftUI

struct InitialSetupView: View {
    
    // MARK: - Binding
    @Binding var showInitialSetup: Bool
    
    // MARK: - State Properties
    @State private var currentStep = 0
    @State private var selectedGrade = 1
    @State private var selectedClass = 1
    @State private var notificationsEnabled = false
    
    // MARK: - Private Properties
    private let totalSteps = 3
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 진행 상태
                progressIndicator
                
                // 단계별 컨텐츠
                stepContent
                
                Spacer()
                
                // 하단 버튼들
                bottomButtons
            }
            .appPadding()
            .navigationTitle(NSLocalizedString(LocalizationKeys.initialSetup, comment: ""))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - View Components
    
    /// 진행 상태 인디케이터
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.appPrimary : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    if step < totalSteps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? Color.appPrimary : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            
            Text("\(currentStep + 1) / \(totalSteps)")
                .captionStyle()
        }
    }
    
    /// 단계별 컨텐츠
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            gradeClassStep
        case 2:
            notificationStep
        default:
            EmptyView()
        }
    }
    
    /// 환영 단계
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 80))
                .foregroundColor(.appPrimary)
            
            Text(NSLocalizedString(LocalizationKeys.welcomeMessage, comment: ""))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(NSLocalizedString(LocalizationKeys.setupDescription, comment: ""))
                .bodyStyle()
                .multilineTextAlignment(.center)
        }
    }
    
    /// 학년/반 선택 단계
    private var gradeClassStep: some View {
        VStack(spacing: 30) {
            VStack(spacing: 8) {
                Text(NSLocalizedString(LocalizationKeys.selectGradeClass, comment: ""))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(NSLocalizedString(LocalizationKeys.gradeClassRequired, comment: ""))
                    .captionStyle()
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString(LocalizationKeys.grade, comment: ""))
                        .bodyStyle()
                    
                    Picker("학년", selection: $selectedGrade) {
                        ForEach(AppConstants.School.grades, id: \.self) { grade in
                            Text(String(format: NSLocalizedString(LocalizationKeys.gradeX, comment: ""), grade)).tag(grade)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                VStack(alignment: .leading) {
                    Text(NSLocalizedString(LocalizationKeys.classKey, comment: ""))
                        .bodyStyle()
                    
                    Picker("반", selection: $selectedClass) {
                        ForEach(AppConstants.School.classes, id: \.self) { classNumber in
                            Text(String(format: NSLocalizedString(LocalizationKeys.classX, comment: ""), classNumber)).tag(classNumber)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                }
            }
        }
    }
    
    /// 알림 설정 단계
    private var notificationStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(.appPrimary)
            
            VStack(spacing: 8) {
                Text(NSLocalizedString(LocalizationKeys.notificationSetup, comment: ""))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(NSLocalizedString(LocalizationKeys.notificationQuestion, comment: ""))
                    .bodyStyle()
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Toggle(NSLocalizedString(LocalizationKeys.receiveClassNotifications, comment: ""), isOn: $notificationsEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .appPrimary))
                
                if notificationsEnabled {
                    Text(NSLocalizedString(LocalizationKeys.notificationInfo, comment: ""))
                        .captionStyle()
                        .foregroundColor(.successColor)
                } else {
                    Text(NSLocalizedString(LocalizationKeys.settingsLater, comment: ""))
                        .captionStyle()
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    /// 하단 버튼들
    private var bottomButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(NSLocalizedString(LocalizationKeys.previous, comment: "")) {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .secondaryButtonStyle()
            }
            
            Spacer()
            
            Button(currentStep == totalSteps - 1 ? NSLocalizedString(LocalizationKeys.complete, comment: "") : NSLocalizedString(LocalizationKeys.next, comment: "")) {
                if currentStep == totalSteps - 1 {
                    completeSetup()
                } else {
                    withAnimation {
                        currentStep += 1
                    }
                }
            }
            .primaryButtonStyle()
        }
    }
    
    // MARK: - Private Methods
    
    /// 설정 완료
    private func completeSetup() {
        // 설정 저장
        UserDefaults.standard.set(selectedGrade, forKey: AppConstants.UserDefaultsKeys.defaultGrade)
        UserDefaults.standard.set(selectedClass, forKey: AppConstants.UserDefaultsKeys.defaultClass)
        UserDefaults.standard.set(notificationsEnabled, forKey: AppConstants.UserDefaultsKeys.notificationsEnabled)
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.initialSetupCompleted)
        
        // 알림 권한 요청 (필요한 경우)
        if notificationsEnabled {
            Task {
                let _ = await NotificationService.shared.requestAuthorization()
                
                // 시간표 로드 및 알림 설정
                await ScheduleService.shared.loadSchedule(grade: selectedGrade, classNumber: selectedClass)
                await ScheduleService.shared.updateNotifications(grade: selectedGrade, classNumber: selectedClass)
            }
        }
        
        // 초기 설정 완료
        withAnimation {
            showInitialSetup = false
        }
        
        print("✅ 초기 설정 완료: \(selectedGrade)학년 \(selectedClass)반, 알림: \(notificationsEnabled)")
    }
}

// MARK: - 미리보기
struct InitialSetupView_Previews: PreviewProvider {
    static var previews: some View {
        InitialSetupView(showInitialSetup: .constant(true))
            .previewDisplayName("초기 설정")
    }
}