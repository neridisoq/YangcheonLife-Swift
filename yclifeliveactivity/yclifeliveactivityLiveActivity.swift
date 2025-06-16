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
                // Expanded View
                DynamicIslandExpandedRegion(.leading) {
                    ClassStatusView(status: context.state.currentStatus)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimeRemainingView(startDate: Date(timeIntervalSince1970: context.state.startDate), endDate: Date(timeIntervalSince1970: context.state.endDate))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ClassInfoView(
                        currentClass: context.state.currentClass,
                        nextClass: context.state.nextClass,
                        status: context.state.currentStatus
                    )
                }
            } compactLeading: {
                // Compact Leading
                Text(context.state.currentStatus.emoji)
                    .font(.caption2)
            } compactTrailing: {
                // Compact Trailing - 00:00에서 멈추도록 수정
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let now = timeline.date
                    let endDate = Date(timeIntervalSince1970: context.state.endDate)
                    
                    if now >= endDate {
                        // 시간이 지나면 00:00으로 고정
                        Text("00:00")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else {
                        // 아직 시간이 남아있으면 카운트다운
                        Text(endDate, style: .timer)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            } minimal: {
                // Minimal
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
            
            // Apple 정책 준수: 시스템 내장 시간 표시 사용  
            VStack(spacing: 4) {
                // 간결한 타이머 형식으로 공간 절약 - 00:00에서 멈추도록 수정
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let now = timeline.date
                    let endDate = Date(timeIntervalSince1970: context.state.endDate)
                    
                    if now >= endDate {
                        // 시간이 지나면 00:00으로 고정
                        Text("00:00")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    } else {
                        // 아직 시간이 남아있으면 카운트다운
                        Text(endDate, style: .timer)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                
                // TimelineView로 진행바 계산
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let now = timeline.date
                    let startDate = Date(timeIntervalSince1970: context.state.startDate)
                    let endDate = Date(timeIntervalSince1970: context.state.endDate)
                    let totalDuration = endDate.timeIntervalSince(startDate)
                    let elapsed = now.timeIntervalSince(startDate)
                    let progress = min(max(elapsed / totalDuration, 0), 1)
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .frame(height: 6)
                }
                
                Text("남음")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 90)
            
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
                            if let _ = context.state.currentClass {
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
    let startDate: Date
    let endDate: Date
    
    var body: some View {
        // Apple 정책 준수: 간결한 타이머 형식 사용 - 00:00에서 멈추도록 수정
        VStack(spacing: 2) {
            Text("⏱️")
                .font(.title3)
            
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                let now = timeline.date
                
                if now >= endDate {
                    // 시간이 지나면 00:00으로 고정
                    Text("00:00")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    // 아직 시간이 남아있으면 카운트다운
                    Text(endDate, style: .timer)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
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

