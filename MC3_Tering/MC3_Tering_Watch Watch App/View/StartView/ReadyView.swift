//
//  ReadyView.swift
//  MC3_Tering_Watch Watch App
//
//  Created by KimTaeHyung on 2023/07/25.
//

import SwiftUI

// MARK: - 운동 시작 준비 화면 (3 2 1 시작)
struct ReadyView: View {
    @State private var progressValue: Float = 0.0
    @State private var countValue: String = ""
    @State var counting: Int = 0
    @State private var fontSize: CGFloat = 48.0
    let readyStatus = ["준비", "3", "2", "1", "시작!"]
    @State private var isCountingViewPresented: Bool = false

    @EnvironmentObject var swingInfo: SwingInfo
    @EnvironmentObject var workoutResultInfo: WorkoutResultInfo
    
    var body: some View {
        VStack {
            TimeCircleProgressBar(progress: self.$progressValue, count: self.$countValue, fontSize: self.$fontSize)
                .frame(width: 150, height: 150, alignment: .center)
                .onAppear {
                    //초기화
                    resetValues()
                }
        }
        .background(
            NavigationLink(destination: CountingView(),
                           isActive: $isCountingViewPresented) {
                EmptyView()
            }
            .hidden()
        )
        .navigationBarBackButtonHidden()
    }
}

extension ReadyView {
    
    private func resetValues() {
        progressValue = 0.0
        counting = 0
        startProgressAnimation()
        swingInfo.totalSwingCount = 0
        swingInfo.totalForehandCount = 0
        swingInfo.totalBackhandCount = 0
        swingInfo.forehandPerfect = 0
        swingInfo.backhandPerfect = 0
        swingInfo.swingLeft = swingInfo.selectedValue // 남은 스윙 횟수 = 선택값 으로 초기화
        workoutResultInfo.workOutDate = Date() // 운동 시작일 저장
    }
    
    private func startProgressAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                self.progressValue += 0.33
                self.counting += 1
            }
            if self.progressValue >= 1.0 {
                self.countValue = readyStatus[counting]
                if self.countValue == "시작!" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.isCountingViewPresented = true
                    }
                    return
                }
                
            } else {
                self.countValue = readyStatus[counting]
                self.startProgressAnimation()
            }
        }
    }
    
}

struct ReadyView_Previews: PreviewProvider {
    
    static var previews: some View {
        ReadyView()
            .environmentObject(SwingInfo())
    }
}
