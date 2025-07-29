import SwiftUI

// MARK: - Screen Mode View
struct ScreenModeView: View {
    @EnvironmentObject var dataController: DataController
    @State private var isActive = false
    @State private var selectedMoods: Set<Mood> = []
    @State private var scrollSpeed: Double = 5.0
    @State private var fontSize: CGFloat = 24
    @State private var currentPostIndex = 0
    @State private var timer: Timer?
    @State private var showTimer = false
    @State private var dragOffset: CGFloat = 0
    
    var filteredPosts: [WordPost] {
        let posts = dataController.getPostsByMoods(selectedMoods)
        return posts.isEmpty ? dataController.posts : posts
    }
    
    var body: some View {
        if isActive {
            activeScreenMode
        } else {
            setupScreenMode
        }
    }
    
    // MARK: - Setup View (unchanged)
    var setupScreenMode: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "tv")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Screen Mode")
                    .font(.system(size: 32, weight: .light, design: .serif))
                
                Text("Transform your screen into a peaceful display of words")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Mood Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Filter by Mood")
                            .font(.system(size: 18, weight: .medium))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                MoodToggleChip(
                                    mood: mood,
                                    isSelected: selectedMoods.contains(mood)
                                ) {
                                    if selectedMoods.contains(mood) {
                                        selectedMoods.remove(mood)
                                    } else {
                                        selectedMoods.insert(mood)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Scroll Speed
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scroll Speed")
                            .font(.system(size: 18, weight: .medium))
                        
                        HStack {
                            Text("Slow")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Slider(value: $scrollSpeed, in: 2...10, step: 1)
                                .accentColor(.blue)
                            
                            Text("Fast")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(Int(scrollSpeed)) seconds per word")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    // Font Size
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Font Size")
                            .font(.system(size: 18, weight: .medium))
                        
                        HStack {
                            Text("Small")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Slider(value: $fontSize, in: 18...36, step: 2)
                                .accentColor(.blue)
                            
                            Text("Large")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Size: \(Int(fontSize))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Start Button
            Button("Start Screen Mode") {
                startScreenMode()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(filteredPosts.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(filteredPosts.isEmpty)
            .padding(.bottom, 20)
            
            if filteredPosts.isEmpty {
                Text("No words available with selected filters")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Active Screen Mode (Redesigned)
    var activeScreenMode: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                HStack(spacing: 0) {
                    // Left Side - Posts
                    ZStack {
                        if !filteredPosts.isEmpty {
                            filteredPosts[currentPostIndex].backgroundType.gradient
                        }
                        
                        VStack {
                            // Exit button
                            HStack {
                                Button("Exit") {
                                    stopScreenMode()
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(20)
                                
                                Spacer()
                                
                                if !filteredPosts.isEmpty {
                                    Text("\(currentPostIndex + 1) / \(filteredPosts.count)")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(20)
                                }
                            }
                            .padding()
                            
                            Spacer()
                            
                            // Current Post
                            if !filteredPosts.isEmpty {
                                ScrollView {
                                    Text(filteredPosts[currentPostIndex].content)
                                        .font(.system(size: fontSize, weight: .light, design: .serif))
                                        .foregroundColor(filteredPosts[currentPostIndex].backgroundType.textColor)
                                        .multilineTextAlignment(.center)
                                        .padding(40)
                                }
                                .transition(.opacity.combined(with: .scale))
                            }
                            
                            Spacer()
                            
                            // Mood Indicators
                            if !filteredPosts.isEmpty {
                                HStack(spacing: 12) {
                                    ForEach(filteredPosts[currentPostIndex].moods, id: \.self) { mood in
                                        Text("\(mood.icon)")
                                            .font(.system(size: 20))
                                            .padding(8)
                                            .background(Color.black.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.bottom, 40)
                            }
                        }
                    }
                    .frame(width: geometry.size.width / 2)
                    
                    // Right Side - Clock/Timer (Fixed in place)
                    ZStack {
                        // Background - same dark theme
                        LinearGradient(
                            colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Clock View
                        ClockView()
                            .opacity(showTimer ? 0 : 1)
                            .scaleEffect(showTimer ? 0.8 : 1)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showTimer)
                        
                        // Timer View
                        TimerView()
                            .opacity(showTimer ? 1 : 0)
                            .scaleEffect(showTimer ? 1 : 0.8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showTimer)
                    }
                    .frame(width: geometry.size.width / 2)
                    .clipped()
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                withAnimation {
                                    if value.translation.width < -50 && !showTimer {
                                        showTimer = true
                                    } else if value.translation.width > 50 && showTimer {
                                        showTimer = false
                                    }
                                }
                            }
                    )
                }
            }
            .navigationBarHidden(true)
            .statusBar(hidden: true)
            .onAppear {
                startTimer()
                // Lock to landscape
                AppDelegate.orientationLock = .landscape
                
                if #available(iOS 16.0, *) {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
                        print("Orientation change error: \(error)")
                    }
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                    UINavigationController.attemptRotationToDeviceOrientation()
                }
            }
            .onDisappear {
                stopTimer()
                // Lock back to portrait
                AppDelegate.orientationLock = .portrait
                
                if #available(iOS 16.0, *) {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
                        print("Orientation change error: \(error)")
                    }
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    UINavigationController.attemptRotationToDeviceOrientation()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func startScreenMode() {
        guard !filteredPosts.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            isActive = true
            currentPostIndex = 0
        }
    }
    
    private func stopScreenMode() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isActive = false
        }
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: scrollSpeed, repeats: true) { _ in
            nextPost()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func nextPost() {
        guard !filteredPosts.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            currentPostIndex = (currentPostIndex + 1) % filteredPosts.count
        }
    }
}

// MARK: - Clock View
struct ClockView: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 40) {
                // Digital Clock
                VStack(spacing: 10) {
                    Text(currentTime, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                        .font(.system(size: 80, weight: .thin, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .blue.opacity(0.5), radius: 10)
                    
                    Text(currentTime, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Analog Clock
                AnalogClockView(currentTime: currentTime)
                    .frame(width: 200, height: 200)
                
                // Swipe indicator
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Timer")
                    Image(systemName: "chevron.left")
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Analog Clock View
struct AnalogClockView: View {
    let currentTime: Date
    
    var hourAngle: Angle {
        let hour = Calendar.current.component(.hour, from: currentTime)
        let minute = Calendar.current.component(.minute, from: currentTime)
        return Angle(degrees: (Double(hour % 12) + Double(minute) / 60) * 30 - 90)
    }
    
    var minuteAngle: Angle {
        let minute = Calendar.current.component(.minute, from: currentTime)
        return Angle(degrees: Double(minute) * 6 - 90)
    }
    
    var secondAngle: Angle {
        let second = Calendar.current.component(.second, from: currentTime)
        return Angle(degrees: Double(second) * 6 - 90)
    }
    
    var body: some View {
        ZStack {
            // Clock face
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
            
            // Hour markers
            ForEach(0..<12) { hour in
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: hour % 3 == 0 ? 15 : 10)
                    .offset(y: -80)
                    .rotationEffect(Angle(degrees: Double(hour) * 30))
            }
            
            // Hour hand
            Rectangle()
                .fill(Color.white)
                .frame(width: 4, height: 50)
                .offset(y: -25)
                .rotationEffect(hourAngle)
                .shadow(color: .black.opacity(0.3), radius: 2)
            
            // Minute hand
            Rectangle()
                .fill(Color.white)
                .frame(width: 3, height: 70)
                .offset(y: -35)
                .rotationEffect(minuteAngle)
                .shadow(color: .black.opacity(0.3), radius: 2)
            
            // Second hand
            Rectangle()
                .fill(Color.blue)
                .frame(width: 1, height: 80)
                .offset(y: -40)
                .rotationEffect(secondAngle)
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10)
        }
    }
}

// MARK: - Timer View
struct TimerView: View {
    @State private var timerValue: TimeInterval = 0
    @State private var selectedMinutes: Int = 5
    @State private var selectedSeconds: Int = 0
    @State private var isTimerRunning = false
    @State private var timer: Timer?
    
    var formattedTime: String {
        let minutes = Int(timerValue) / 60
        let seconds = Int(timerValue) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 40) {
                // Timer Display
                Text(formattedTime)
                    .font(.system(size: 80, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .green.opacity(0.5), radius: 10)
                
                // Timer Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 20)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(timerValue / (Double(selectedMinutes * 60 + selectedSeconds))))
                        .stroke(
                            LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerValue)
                }
                
                // Controls
                if !isTimerRunning {
                    // Time Selector
                    HStack(spacing: 20) {
                        VStack {
                            Text("Minutes")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Picker("Minutes", selection: $selectedMinutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 100)
                            .clipped()
                        }
                        
                        Text(":")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        
                        VStack {
                            Text("Seconds")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Picker("Seconds", selection: $selectedSeconds) {
                                ForEach(0..<60) { second in
                                    Text("\(second)").tag(second)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 100)
                            .clipped()
                        }
                    }
                    
                    Button("Start Timer") {
                        startTimer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.green)
                    .cornerRadius(25)
                } else {
                    // Running Timer Controls
                    HStack(spacing: 20) {
                        Button(action: pauseTimer) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.orange)
                                .cornerRadius(30)
                        }
                        
                        Button(action: resetTimer) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.red)
                                .cornerRadius(30)
                        }
                    }
                }
                
                // Swipe indicator
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                    Text("Clock")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
            }
        }
    }
    
    private func startTimer() {
        timerValue = Double(selectedMinutes * 60 + selectedSeconds)
        isTimerRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timerValue > 0 {
                timerValue -= 1
            } else {
                resetTimer()
                // You could add a notification or sound here
            }
        }
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        isTimerRunning = false
    }
    
    private func resetTimer() {
        timer?.invalidate()
        isTimerRunning = false
        timerValue = 0
    }
}

// MARK: - Mood Toggle Chip (unchanged)
struct MoodToggleChip: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(mood.icon)
                Text(mood.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}
