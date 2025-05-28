//
//  yclifeliveactivityLiveActivity.swift
//  yclifeliveactivity
//
//  Created by neridisoq on 5/28/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

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
                        } else {
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
        let totalMinutes = 50.0 // 수업 시간
        let remaining = Double(context.state.remainingMinutes)
        let elapsed = totalMinutes - remaining
        return elapsed / totalMinutes
    }
}

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

// MARK: - Preview Extensions

extension ClassActivityAttributes {
    fileprivate static var preview: ClassActivityAttributes {
        ClassActivityAttributes(grade: 2, classNumber: 3)
    }
}

extension ClassActivityAttributes.ContentState {
    fileprivate static var inClass: ClassActivityAttributes.ContentState {
        ClassActivityAttributes.ContentState(
            currentStatus: .inClass,
            currentClass: ClassInfo(
                period: 3,
                subject: "수학",
                classroom: "2-3",
                startTime: "10:20",
                endTime: "11:10"
            ),
            nextClass: ClassInfo(
                period: 4,
                subject: "영어",
                classroom: "2-3",
                startTime: "11:20",
                endTime: "12:10"
            ),
            remainingMinutes: 25,
            lastUpdated: Date()
        )
    }
    
    fileprivate static var breakTime: ClassActivityAttributes.ContentState {
        ClassActivityAttributes.ContentState(
            currentStatus: .breakTime,
            currentClass: nil,
            nextClass: ClassInfo(
                period: 4,
                subject: "영어",
                classroom: "2-3",
                startTime: "11:20",
                endTime: "12:10"
            ),
            remainingMinutes: 8,
            lastUpdated: Date()
        )
    }
}

// Preview removed due to iOS 16.1 compatibility issues
