import WidgetKit
import SwiftUI

struct NextClassWidgetView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(entry.grade)학년 \(entry.classNumber)반")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                }
                .padding(.bottom, 2)
                
                if let nextClass = entry.nextClass {
                    VStack(alignment: .leading, spacing: 4) {
                        // 다음 수업 정보
                        Text("다음 수업")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(nextClass.subject)")
                            .font(.system(size: 18, weight: .bold))
                            .lineLimit(1)
                        
                        // 장소 정보
                        Text("\(nextClass.teacher)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 시간 정보
                        HStack {
                            Text("\(formatTime(nextClass.startTime)) ~ \(formatTime(nextClass.endTime))")
                                .font(.caption2)
                            
                            Spacer()
                            
                            // 남은 시간 표시
                            if let remainingTime = entry.remainingTime {
                                Text(formatRemainingTime(remainingTime))
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                } else {
                    // 다음 수업이 없는 경우
                    Spacer()
                    Text("다음 수업 정보 없음")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
            }
            .padding()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatRemainingTime(_ timeInterval: TimeInterval) -> String {
        if timeInterval < 0 {
            return "진행 중"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분 전"
        } else {
            return "\(minutes)분 전"
        }
    }
}