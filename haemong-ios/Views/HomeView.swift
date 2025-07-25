import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    
    var body: some View {
        ScrollView {
                VStack(spacing: 32) {
                    // 헤더
                    VStack(spacing: 16) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("해몽")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("당신의 꿈을 해석해드립니다")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // 달력
                    dreamCalendarView
                    
                    // 메인 버튼들
                    VStack(spacing: 20) {
                        // 오늘의 해몽 버튼
                        todaysDreamButton
                        
                        // 꿈 일기 (준비중)
                        dreamDiaryButton
                        
                        // 꿈 해석 가이드 (준비중)
                        dreamGuideButton
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("홈")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                store.send(.onAppear)
            }
            .alert("오류", isPresented: .constant(store.errorMessage != nil)) {
                Button("확인") {
                    store.send(.dismissError)
                }
            } message: {
                Text(store.errorMessage ?? "")
            }
            .sheet(isPresented: Binding(
                get: { store.showingRecordDetail },
                set: { _ in store.send(.dismissRecordDetail) }
            )) {
                if let chatRoom = store.selectedDateChatRoom {
                    ChatRecordDetailView(
                        chatRoom: chatRoom, 
                        messages: store.selectedDateMessages, 
                        selectedDate: store.selectedDate
                    )
                }
            }
    }
    
    private var dreamCalendarView: some View {
        VStack(spacing: 16) {
            Text("나의 해몽 달력")
                .font(.title2)
                .fontWeight(.semibold)
            
            CalendarView(
                selectedDate: $store.selectedDate.sending(\.dateSelected),
                currentMonth: $store.currentMonth.sending(\.monthChanged),
                datesWithRecords: store.datesWithRecords,
                isLoading: store.isLoadingCalendar
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
    
    private var todaysDreamButton: some View {
        Button(action: {
            store.send(.todaysDreamButtonTapped)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "message.circle.fill")
                            .font(.title2)
                        Text("오늘의 해몽")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Text("오늘 꾼 꿈을 AI가 해석해드려요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(dreamButtonGradient)
            .cornerRadius(16)
            .overlay(dreamButtonStroke)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dreamDiaryButton: some View {
        Button(action: {}) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "book.circle.fill")
                            .font(.title2)
                        Text("꿈 일기")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Text("나의 꿈과 해몽 기록을 확인해보세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                comingSoonBadge
            }
            .padding(24)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
            .overlay(disabledButtonStroke)
        }
        .disabled(true)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dreamGuideButton: some View {
        Button(action: {}) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.circle.fill")
                            .font(.title2)
                        Text("꿈 해석 가이드")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Text("꿈의 상징과 의미를 알아보세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                comingSoonBadge
            }
            .padding(24)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
            .overlay(disabledButtonStroke)
        }
        .disabled(true)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dreamButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var dreamButtonStroke: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
    }
    
    private var disabledButtonStroke: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
    
    private var comingSoonBadge: some View {
        Text("준비중")
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(.secondary)
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Binding var currentMonth: Date
    let datesWithRecords: Set<String>
    let isLoading: Bool
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter.apiDateFormatter
    
    var body: some View {
        VStack(spacing: 12) {
            // 월 네비게이션
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if isLoading {
                ProgressView()
                    .frame(height: 200)
            } else {
                // 요일 헤더
                HStack {
                    ForEach(Calendar.current.veryShortWeekdaySymbols, id: \.self) { weekday in
                        Text(weekday)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // 날짜 그리드
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(daysInMonth, id: \.self) { date in
                        DayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasRecord: hasRecord(for: date),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            onTap: hasRecord(for: date) ? { selectedDate = date } : nil
                        )
                    }
                }
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1) else {
            return []
        }
        
        var days: [Date] = []
        var date = monthFirstWeek.start
        
        while date < monthLastWeek.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
    
    private func hasRecord(for date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        return datesWithRecords.contains(dateString)
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

struct DayView: View {
    let date: Date
    let isSelected: Bool
    let hasRecord: Bool
    let isCurrentMonth: Bool
    let onTap: (() -> Void)?
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    dayContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                dayContent
            }
        }
    }
    
    private var dayContent: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(textColor)
            
            if hasRecord {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(width: 36, height: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary
        } else if isSelected {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else {
            return .clear
        }
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}