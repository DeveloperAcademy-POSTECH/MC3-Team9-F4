//
//  MC3_Tering_WatchApp.swift
//  MC3_Tering_Watch Watch App
//
//  Created by KimTaeHyung on 2023/07/25.
//

import SwiftUI

@main
struct MC3_Tering_Watch_Watch_AppApp: App {
    @StateObject var swingListWrapper = SwingListWrapper(swingList: SwingList(name: "", guideButton: "", gifImage: ""))
    @StateObject var healthStartInfo = HealthStartInfo() // Create an instance of HealthStartInfo
    @StateObject var healthResultInfo = HealthResultInfo()
    @StateObject var swingInfo = SwingInfo()
    
    var body: some Scene {
        WindowGroup {
//            TestWatchView()
            SwingListView(swingList: swingLists[0])
                .environmentObject(swingListWrapper)
                .environmentObject(healthStartInfo)
                .environmentObject(healthResultInfo)
                .environmentObject(swingInfo)
            //이거 왜 이러는거임?
        }
    }
}
