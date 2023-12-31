//
//  SwingCountView.swift
//  MC3_Tering_Watch Watch App
//
//  Created by KimTaeHyung on 2023/07/25.
//

import SwiftUI

// MARK: - 운동 목표 스윙 개수 설정 화면
struct SwingCountView: View {
    @State private var isReadyViewActive = false
    @State private var strokeCount = 10

    @EnvironmentObject var workoutManager: WorkoutManager

    @EnvironmentObject var swingInfo: SwingInfo

    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("이번 목표 스윙 개수는\n얼마인가요?")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                HStack {
                    selectingGoalView()
                }
                Spacer()
                NavigationLink(destination: ReadyView()) {
                    Text("시작")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.black)
                }
                .background(Color.watchColor.lightGreen)
                .cornerRadius(40)
            }
            .onAppear {
                workoutManager.requestAuthorization()
            }
            .navigationBarBackButtonHidden()
            .navigationTitle("목록")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SwingCountView_Previews: PreviewProvider {
    static var previews: some View {
        SwingCountView()
            .environmentObject(WorkoutManager())
            .environmentObject(SwingInfo())
    }
}

struct selectingGoalView: View {
    @State private var valueIndex: Int = 0
    let stepSize = 10
    let values: [Int]
    @EnvironmentObject var swingInfo: SwingInfo
    
    init() {
        // Create an array from 0 to 100 (inclusive) with a step of 10
        var tempValues: [Int] = []
        for i in stride(from: 10, through: 100, by: stepSize) {
            tempValues.append(i)
        }
        self.values = tempValues
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: decrementValue) {
                    Image(systemName: "minus")
                        .foregroundColor(Color.black)
                }
                .background(Color.watchColor.lightGreen)
                .clipShape(Circle())
                .padding()

                Picker("Value", selection: $valueIndex) {
                    ForEach(0..<values.count) { index in
                        Text("\(values[index])")
                    }
                }
                .pickerStyle(WheelPickerStyle()) // Set the picker style to WheelPickerStyle
                .labelsHidden()
                

                Button(action: incrementValue) {
                    Image(systemName: "plus")
                        .foregroundColor(Color.black)
                }
                .background(Color.watchColor.lightGreen)
                .clipShape(Circle())
                .padding()
            }
        }
        .onAppear {
            // 목표 스윙 횟수 선택 안했을 경우 초기값이 있어야 하기 때문에 초기값 세팅
            swingInfo.selectedValue = values[valueIndex]
        }
        .onChange(of: valueIndex) { newValue in
            swingInfo.selectedValue = values[newValue]
//            print("목표 스윙 횟수 선택 \(swingInfo.selectedValue)")
        }
    }

    private func incrementValue() {
        if valueIndex < values.count - 1 {
            valueIndex += 1
        }
    }

    private func decrementValue() {
        if valueIndex > 0 {
            valueIndex -= 1
        }
    }
}
