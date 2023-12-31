//
//  ResultView.swift
//  MC3_Tering_Watch Watch App
//
//  Created by KimTaeHyung on 2023/07/25.
//

import SwiftUI
import CoreMotion
import WatchKit
import SpriteKit
import HealthKit

// MARK: - 운동 결과화면 탭뷰
struct ResultView: View {
    @State private var selectedTab = 1
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                
                ResultEffectView()
                .tabItem{
                    Image(systemName: "tennisball.fill")
                        .foregroundColor(Color.watchColor.lightGreen)
                }
                .tag(0)
                
                SwingRateView()
                .tabItem{
                    Image(systemName: "tennisball.fill")
                        .foregroundColor(Color.watchColor.lightGreen)
                }
                .tag(1)
                
                HealthKitView()
                .tabItem{
                    Image(systemName: "tennisball.fill")
                        .foregroundColor(Color.watchColor.lightGreen)
                }
                .tag(2)
            }
            .onAppear {
                selectedTab = 1
            }
        }
        .navigationTitle("요약")
        .navigationBarBackButtonHidden()
        .onDisappear {
            workoutManager.resetWorkout()
        }
    }
}

//MARK: - Tag(0) 파티클 뷰
struct ResultEffectView: View {
    
    @State private var offsets: [CGSize] = []
    @State private var perfectCount: Int = 8
    @State private var isLiked: [Bool] = []
    
    private let motionManager = CMMotionManager()
    
    var body: some View {
        ZStack {
            ForEach(offsets.indices, id: \.self) { index in
                CustomButton(systemImage: "tennisBall", status: isLiked[index], activeTint: .pink, inActiveTint: .gray) {
                    isLiked[index].toggle()
                }
                .offset(x: validOffset(at: index).width, y: validOffset(at: index).height)
                .animation(.easeOut(duration: 0.5))
            }
        }
        .onAppear {
            initializeOffsets()
            startMotionUpdates()
            isLiked = Array(repeating: false, count: perfectCount)
        }
        .onDisappear {
            stopMotionUpdates()
        }
    }
    
    func CustomButton(systemImage: String, status: Bool, activeTint: Color, inActiveTint: Color, onTap: @escaping () -> ()) -> some View {
        Image("tennisBall")
            .resizable()
            .frame(width: 40, height: 40)
            .foregroundColor(status ? activeTint : inActiveTint)
            .particleEffect(systemImage: systemImage, font: .title2, status: status, activeTint: activeTint, inActiveTint: inActiveTint)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .onTapGesture(perform: onTap)
    }
    
    
    private func initializeOffsets() {
        offsets = Array(repeating: .zero, count: perfectCount)
    }
    
    private func validOffset(at index: Int) -> CGSize {
        guard index >= 0 && index < offsets.count else {
            return .zero
        }
        return offsets[index]
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (motion, error) in
            guard let motion = motion else { return }
            
            let pitch = motion.attitude.pitch
            let roll = motion.attitude.roll
            
            DispatchQueue.main.async {
                self.updateOffsets(pitch: pitch, roll: roll)
            }
        }
    }
    
    private func updateOffsets(pitch: Double, roll: Double) {
        offsets.indices.forEach { index in
            let randomOffset = CGSize(width: CGFloat.random(in: -50...50), height: CGFloat.random(in: -50...50))
            offsets[index] = CGSize(width: CGFloat(roll) * 100 + randomOffset.width, height: CGFloat(pitch) * 100 + randomOffset.height)
        }
    }
    
    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}



// MARK: - Tag(1) 원형 바 운동 결과 뷰
struct SwingRateView: View {
    @State var progressValue: Float = 0.0
    @State var fontSize: CGFloat = 20.0
    @EnvironmentObject var swingInfo: SwingInfo
    
    var body: some View {
        VStack {
            Spacer()
            ResultCircleProgressBar(progress: self.$progressValue, fontSize: self.$fontSize)
                .frame(width: 150, height: 150, alignment: .center)
        }
        .onAppear {
            perfectRate()
        }
    }
    
    private func perfectRate() {
        progressValue = Float((swingInfo.forehandPerfect ?? 0) + (swingInfo.backhandPerfect ?? 0)) / Float(swingInfo.totalSwingCount ?? 0)
    }
}

// MARK: - Tag(2) Workout 결과 확인 뷰
struct HealthKitView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var durationFormatter: DateComponentsFormatter = { // 운동 시간 formatter
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    @EnvironmentObject var workoutResultInfo: WorkoutResultInfo
    @EnvironmentObject var viewModelWatch: ViewModelWatch
    @EnvironmentObject var swingInfo: SwingInfo
    
    @State private var isFirstAppear = false
    
    var body: some View {
        VStack {
            if workoutManager.isSaved == false {
                VStack(alignment: .leading, spacing: 0) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .frame(width: 35, height: 33)
                        .padding(.top, 7)
                        .padding(.bottom, 6)
                    Text("10초 미만의 운동 데이터는\n저장되지 않습니다.")
                        .font(.system(size: 18, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
            } else {
                if workoutManager.workout == nil {
                    ProgressView("운동 결과 저장 중...")
                        .navigationBarHidden(true)
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                        Text(durationFormatter.string(from: workoutManager.workout?.duration ?? 0.0) ?? "")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(Color.watchColor.lightGreen)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 15)
                            .padding(.bottom, 3)
                        Text(workoutManager.averageHeartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
                            .font(.system(size: 28, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 3)
                        Text(Measurement(
                            value: workoutManager.workout?.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                            unit: UnitEnergy.kilocalories).formatted(.measurement(width: .abbreviated, usage: .workout, numberFormatStyle: .number.precision(.fractionLength(0)))))
                            .font(.system(size: 28, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 3)
                        Spacer()
                    }
                    .onAppear {
                        if !isFirstAppear {
                            print("===============================결과 확인===================================")
                            print("저장된 평균 심박수 : \(workoutResultInfo.averageHeartRate)")
                            print("저장된 소모 칼로리 : \(workoutResultInfo.burningCal)")
                            print("저장된 운동 시간 : \(workoutResultInfo.workOutTime)")
                            print("저장된 운동일 : \(workoutResultInfo.workOutDate)")
                            print("======================================================================")
                            sendSwingDataToPhone()
                            
                            isFirstAppear = true
                        }
                    }
                }
            }
            
            NavigationLink(destination: SwingCountView()) {
                Text("완료")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.black)
            }
            .foregroundColor(Color.watchColor.black) // 2
            .background(Color.watchColor.lightGreen) // 3
            .cornerRadius(40)
        }
        .padding(.horizontal, 5)
    }

}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitView()
            .environmentObject(WorkoutManager())
            .environmentObject(WorkoutResultInfo())
    }
}

extension HealthKitView {
    private func sendSwingDataToPhone() {
        self.viewModelWatch.session.transferUserInfo([
            "totalSwingCount" : self.swingInfo.totalSwingCount,
            "forehandPerfect" : self.swingInfo.forehandPerfect,
            "totalForehandCount" : self.swingInfo.totalForehandCount,
            "backhandPerfect" : self.swingInfo.backhandPerfect,
            "totalBackhandCount" : self.swingInfo.totalBackhandCount,
            "selectedValue" : self.swingInfo.selectedValue,
            "averageHeartRate" : workoutResultInfo.averageHeartRate, // 평균 심박수
            "burningCal" : workoutResultInfo.burningCal, // 소모 칼로리
            "workOutTime" : workoutResultInfo.workOutTime, // 운동 시간
            "workOutDate" : workoutResultInfo.workOutDate // 운동일
        ])
    }
}
