//
//  yclifeliveactivityLiveActivity.swift
//  yclifeliveactivity
//
//  Created by neridisoq on 5/28/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 18.0, *)
struct ClassLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClassActivityAttributes.self) { context in
            ClassLiveActivityView(context: context)
                .activityBackgroundTint(Color.clear)
                .activitySystemActionForegroundColor(Color.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ClassStatusView(status: context.state.currentStatus)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimeRemainingView(minutes: context.state.remainingMinutes)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ClassInfoView(
                        currentClass: context.state.currentClass,
                        nextClass: context.state.nextClass,
                        status: context.state.currentStatus
                    )
                }
            } compactLeading: {
                Text(context.state.currentStatus.emoji)
                    .font(.caption2)
            } compactTrailing: {
                Text("\(context.state.remainingMinutes)분")
                    .font(.caption2)
                    .fontWeight(.medium)
            } minimal: {
                Text(context.state.currentStatus.emoji)
            }
            .keylineTint(Color.blue)
        }
    }
}

// MARK: - Live Activity Views

@available(iOS 18.0, *)
struct ClassLiveActivityView: View {
    let context: ActivityViewContext<ClassActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            // 현재 수업 (왼쪽)
            VStack(alignment: .leading, spacing: 8) {
                Text("현재 시간")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let currentClass = context.state.currentClass {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(currentClass.period)교시")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(currentClass.getDisplaySubject())
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(currentClass.getDisplayClassroom())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        if context.state.currentStatus == .lunchTime {
                            Text("점심시간")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Lunch Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            // 5교시 전 쉬는시간인지 확인
                            if let nextClass = context.state.nextClass, nextClass.period == 5 {
                                Text("쉬는시간")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Before 5th Period")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("쉬는 시간")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Break Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 진행 바와 시간 (중앙)
            VStack(spacing: 6) {
                Text("\(context.state.remainingMinutes)분")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // 진행 바
                ProgressView(value: getProgressValue(context: context), total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    .frame(height: 4)
                
                Text("남음")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            
            // 다음 시간 (오른쪽)
            VStack(alignment: .trailing, spacing: 8) {
                Text("다음 시간")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let nextClass = context.state.nextClass {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(nextClass.period)교시")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(nextClass.getDisplaySubject())
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(nextClass.getDisplayClassroom())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        // 4교시이고 다음이 점심시간인 경우
                        if let currentClass = context.state.currentClass, currentClass.period == 4 {
                            Text("점심시간")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Lunch Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        // 점심시간 중이고 다음이 5교시인 경우
                        else if context.state.currentStatus == .lunchTime {
                            Text("5교시")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("5th Period")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        // 5교시 전 쉬는시간 중이고 다음이 5교시인 경우
                        else if context.state.currentStatus == .breakTime || context.state.currentStatus == .preClass {
                            if let currentClass = context.state.currentClass {
                                // 수업 중이 아니라면 다음 수업 표시
                                Text("수업 끝")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("End of Day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("수업 끝")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("End of Day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        else {
                            Text("수업 끝")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("End of Day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func getProgressValue(context: ActivityViewContext<ClassActivityAttributes>) -> Double {
        let status = context.state.currentStatus
        let remaining = Double(context.state.remainingMinutes)
        
        var totalMinutes: Double
        
        switch status {
        case .inClass:
            totalMinutes = 50.0 // 수업 시간
        case .breakTime:
            totalMinutes = 10.0 // 쉬는시간
        case .lunchTime:
            totalMinutes = 50.0 // 점심시간 (12:10 ~ 13:00)
        case .preClass:
            // 5교시 전 쉬는시간 (13:00 ~ 13:10)은 10분
            if let currentClass = context.state.currentClass, currentClass.period == 5 {
                totalMinutes = 10.0
            } else {
                totalMinutes = 10.0 // 일반 수업 전 시간
            }
        default:
            totalMinutes = 50.0 // 기본값
        }
        
        let elapsed = totalMinutes - remaining
        return max(0, min(1, elapsed / totalMinutes))
    }
}

@available(iOS 18.0, *)
struct ClassCardView: View {
    let classInfo: ClassInfo
    let title: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(classInfo.period)교시 \(classInfo.getDisplaySubject())")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(classInfo.startTime) - \(classInfo.endTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(classInfo.getDisplayClassroom())
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

@available(iOS 18.0, *)
struct ClassStatusView: View {
    let status: ClassStatus
    
    var body: some View {
        VStack(spacing: 2) {
            Text(status.emoji)
                .font(.title3)
            Text(status.displayText)
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

@available(iOS 18.0, *)
struct TimeRemainingView: View {
    let minutes: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text("⏱️")
                .font(.title3)
            if minutes > 0 {
                Text("\(minutes)분")
                    .font(.caption2)
                    .fontWeight(.bold)
                Text("남음")
                    .font(.caption2)
            } else {
                Text("-")
                    .font(.caption2)
            }
        }
    }
}

@available(iOS 18.0, *)
struct ClassInfoView: View {
    let currentClass: ClassInfo?
    let nextClass: ClassInfo?
    let status: ClassStatus
    
    var body: some View {
        VStack(spacing: 8) {
            if let currentClass = currentClass {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("현재 수업")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(currentClass.period)교시 \(currentClass.getDisplaySubject())")
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text(currentClass.getDisplayClassroom())
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            } else if status == .lunchTime {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("현재 시간")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("점심시간")
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text("🍽️")
                        .font(.caption2)
                }
            }
            
            if let nextClass = nextClass {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("다음 수업")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(nextClass.period)교시 \(nextClass.getDisplaySubject())")
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text(nextClass.getDisplayClassroom())
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            } else if let currentClass = currentClass, currentClass.period == 4 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("다음 시간")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("점심시간")
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text("🍽️")
                        .font(.caption2)
                }
            }
        }
    }
}

