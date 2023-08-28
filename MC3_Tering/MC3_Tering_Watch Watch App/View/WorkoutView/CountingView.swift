//
//  CountingView.swift
//  MC3_Tering_Watch Watch App
//
//  Created by KimTaeHyung on 2023/07/25.
//

import SwiftUI

//MARK: - tag0, tag1 위치 바꾸기

struct CountingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject var tennisClassifierViewModel = TennisClassifierViewModel.shared
    
    @State private var selectedTab = 1
//    @Binding var selectedValue: Int
    
    @EnvironmentObject var swingInfo: SwingInfo
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            QuitView()
                .tabItem{
                    Image(systemName: "tennisball.fill")
                        .foregroundColor(Color.watchColor.lightGreen)
                }
                .tag(0)
            
            ChekingSwingView()
                .tabItem{
                    Image(systemName: "tennisball.fill")
                        .foregroundColor(Color.watchColor.lightGreen)
                }
                .tag(1)
        }
        .onAppear {
            selectedTab = 1
            if tennisClassifierViewModel.isDetecting == false {
                // 운동 세션 및 동작 감지 시작
                workoutManager.startWorkout()
//                tennisClassifierViewModel.startMotionTracking()
            }
        }
        .navigationBarBackButtonHidden()
    }
}

//MARK: - 종료 뷰

struct QuitView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject var tennisClassifierViewModel = TennisClassifierViewModel.shared
    
//    @State var swingLeft: Int = 10
    @State var showResultView = false
    
//    @ObservedObject var healthManager = HealthKitManager()
//    @EnvironmentObject var healthInfo: HealthStartInfo // Access the shared instance
//    @EnvironmentObject var healthResultInfo: HealthResultInfo
    @ObservedObject var model = ViewModelWatch()
    @EnvironmentObject var swingInfo: SwingInfo
    
    @State private var workoutTimeFormatter: DateComponentsFormatter = { // 운동 시간 formatter
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    @EnvironmentObject var healthResultInfo: HealthResultInfo
    
    var body: some View {
        TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date())) { context in
            VStack(alignment: .leading) {
                Spacer()
                // context의 cadence 값에 따라 subseconds를 보여줄지 말지 결정
                ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime(at: context.date) ?? 0, showSubseconds: context.cadence == .live)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(Color.watchColor.lightGreen)
                Text(swingInfo.swingLeft! > 0 ? "\(swingInfo.swingLeft!)번의 스윙이 남았어요.\n연습을 끝내시겠어요?" : "연습을 끝내시겠어요?")
                    .font(.system(size: 15))
                Spacer()
                
                NavigationLink(destination: ResultView(workoutDataModel: WorkOutDataModel()), isActive: $showResultView, label: {
                    Button("종료") {
                        // Workout 데이터 HealthResultInfo 모델에 저장 (운동 시간이 10초 이상일 때만 저장)
                        if Int(workoutManager.builder?.elapsedTime(at: context.date) ?? 0) >= 10 {
                            healthResultInfo.workOutTime = Int(((workoutManager.builder?.elapsedTime(at: context.date) ?? 0) / 60).rounded()) // 운동 시간(초 -> 분 단위로 변환)
                            healthResultInfo.burningCal = Int(workoutManager.activeEnergy.rounded()) // 소모 칼로리
                            healthResultInfo.averageHeartRate = Int(workoutManager.averageHeartRate.rounded()) // 평균 심박수
                            workoutManager.isSaved = true
                        } else {
                            print("10초 미만의 운동 결과는 저장되지 않습니다. -> \(Int(workoutManager.builder?.elapsedTime(at: context.date) ?? 0))초")
                        }
                        
                        workoutManager.endWorkout() // 운동 세션 및 모션 감지 종료
                        showResultView = true
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.white)
                    .background(Color.watchColor.lightBlack)
                    .cornerRadius(40)
                })
                .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to remove button visuals
            }
        }
    }
}

//MARK: - 스윙 횟수 확인 뷰

struct ChekingSwingView: View {
    
//    @Binding var selectedValue: Int
    
    @State var progressValue: Float = 0.0
    @State var countValue: String = ""
    @State var fontSize: CGFloat = 48.0
    
    @StateObject var tennisClassifierViewModel = TennisClassifierViewModel.shared
    
    @EnvironmentObject var swingInfo: SwingInfo
    
    
    var body: some View {
        VStack {
            TimeCircleProgressBar(progress: self.$progressValue, count: self.$countValue, fontSize: $fontSize)
                .frame(width: 150, height: 150, alignment: .center)
        }
        .background(
            NavigationLink(destination: MeasuringView(), isActive: tennisClassifierViewModel.isSwingBinding) {
                EmptyView()
            }
            .hidden()
            .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to remove button visuals
            .background(Color.clear) // Make the background transparent
            .disabled(true) // 터치 시 내비게이션 동작 막아둠
        )
        .onAppear {
            rate()
            countSwing()
        }
        .navigationBarBackButtonHidden()
        
//        ZStack {
////            TimeCircleProgressBar(progress: self.$progressValue, count: self.$countValue, fontSize: $fontSize)
////                .frame(width: 150, height: 150, alignment: .center)
//
////            Text("\(tennisClassifierViewModel.timestamp)").foregroundColor(.blue) //MARK: 테스트용
////
//            //MARK: - TimeCircleProgressBar를 NavigationLink에 넣지 않으면 한 번 스윙한 뒤 멈춤
//            // 스윙 결과 확인되면 MeasuringView로 넘어감
//            NavigationLink(destination: MeasuringView(), isActive: tennisClassifierViewModel.isSwingBinding, label: {
//                TimeCircleProgressBar(progress: self.$progressValue, count: self.$countValue, fontSize: $fontSize)
//                    .frame(width: 150, height: 150, alignment: .center)
////                EmptyView()
//            })
//            .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to remove button visuals
//            .background(Color.clear) // Make the background transparent
//            .disabled(true) // 터치 시 내비게이션 동작 막아둠
//        }
//        .onAppear {
//            rate()
//            countSwing()
//        }
    }
}

extension ChekingSwingView {
    
    private func rate() {
        progressValue = Float(swingInfo.totalSwingCount ?? 0) / Float(swingInfo.selectedValue ?? 10)
        print("progressValue \(progressValue)")
    }
    
    private func countSwing() {
        countValue = "\(swingInfo.totalSwingCount ?? 0)"
        print("countValue -> \(countValue)")
    }
}


struct CountingView_Previews: PreviewProvider {
    
    static var previews: some View {
        CountingView()
            .environmentObject(WorkoutManager())
            .environmentObject(SwingInfo())
    }
}

// 활성화된 workout 세션이 있는 앱은 Always On 상태에서 최대 1초에 한 번씩 업데이트가 가능함
// 따라서 Always On 상태에서는 시간 표시에 subseconds가 들어가지 않도록 해주어야 함
struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
//    var isPaused: Bool

//    init(from startDate: Date, isPaused: Bool) {
//        self.startDate = startDate
//        self.isPaused = isPaused
//    }
    init(from startDate: Date) {
        self.startDate = startDate
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> PeriodicTimelineSchedule.Entries {
        PeriodicTimelineSchedule(
            from: self.startDate,
            by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0)
        ).entries(
            from: startDate,
            mode: mode
        )
    }
//    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
//        var baseSchedule = PeriodicTimelineSchedule(from: self.startDate,
//                                                    by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0)) // lowFrequency-1초, normal-1초당30번,
//            .entries(from: startDate, mode: mode)
//
//        return AnyIterator<Date> {
//            guard !isPaused else { return nil }
//            return baseSchedule.next()
//        }
//    }
}
