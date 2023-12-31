//
//  CircleProgressBar.swift
//  MC3-F4-DoWonGyoRi Watch App
//
//  Created by KimTaeHyung on 2023/07/12.
//

import SwiftUI

struct TimeCircleProgressBar: View {
    @Binding var progress: Float
    @Binding var count: String
    @Binding var fontSize: CGFloat
    var gradientColors: [Color] = [Color.watchColor.lightGreen, Color.watchColor.lightBlue]
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 14.0)
                .opacity(0.20)
                .foregroundColor(Color.gray)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 14.0, lineCap: .round, lineJoin: .round))
                .fill(LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .leading, endPoint: .trailing))
                .rotationEffect(Angle(degrees: 270))
                .animation(.easeInOut(duration: 1.0))

            Text(self.count)
                .font(.system(size: self.fontSize, weight: .semibold))
        }
    }
}

struct ResultCircleProgressBar: View {
    @Binding var progress: Float
    @Binding var perfectCount: Int
    @Binding var badCount: Int
    @Binding var fontSize: CGFloat
    var perfectColor: Color = Color.watchColor.lightGreen
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 14.0)
                .foregroundColor(Color.watchColor.pink)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 14.0, lineCap: .round, lineJoin: .round))
                .fill(perfectColor)
                .rotationEffect(Angle(degrees: 270))
                .animation(.easeInOut(duration: 1.0))

            VStack {
                Text("PERFECT")
                    .font(.system(size: self.fontSize, weight: .semibold))
                    .foregroundColor(Color.watchColor.lightGreen)
                
                Text("\(self.perfectCount)회")
                    .font(.system(size: self.fontSize, weight: .bold))
                
                Text("BAD")
                    .font(.system(size: self.fontSize, weight: .semibold))
                    .foregroundColor(Color.watchColor.pink)
                
                Text("\(self.badCount)회")
                    .font(.system(size: self.fontSize, weight: .bold))
            }
        }
    }
}


//MARK: - CircleProgressBar 확인용

//struct ContentView: View {
//    @State var progressValue: Float = 0.0
//    @State var countValue: String = ""
//    @State var counting: Int = 0
//    @State var fontSize: CGFloat = 48.0
//    let readyStatus = ["준비", "3", "2", "1", "시작!"]
//
//
//    var body: some View {
//        VStack {
//            TimeCircleProgressBar(progress: self.$progressValue, count: self.$countValue, fontSize: $fontSize)
//                .frame(width: 150, height: 150, alignment: .center)
//                .onAppear {
//                    startProgressAnimation()
//                }
//        }
//    }
//
//    func startProgressAnimation() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            withAnimation(.easeInOut(duration: 1.0)) {
//                self.progressValue += 0.3
//                self.counting += 1
//            }
//            if self.progressValue >= 1.0 {
//                self.countValue = readyStatus[counting]
//
//            } else {
//                self.countValue = readyStatus[counting]
//                self.startProgressAnimation()
//            }
//        }
//    }
//}

//MARK: - ResultCircleProgressBar 확인용

struct ContentView: View {
    @State var progressValue: Float = 0.0
    @State var perfectCount: Int = 30
    @State var badCount: Int = 30
    @State var fontSize: CGFloat = 20.0


    var body: some View {
        VStack {
            ResultCircleProgressBar(progress: self.$progressValue, perfectCount: self.$perfectCount, badCount: self.$badCount, fontSize: self.$fontSize)
                .frame(width: 180, height: 180, alignment: .center)
        }
        .onAppear {
            rate()
        }
    }

    private func rate() {
        progressValue = Float(perfectCount) / Float((perfectCount + badCount))
    }
}


struct CircleProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
