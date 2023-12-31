//
//  GuideView.swift
//  MC3-F4-DoWonGyoRi Watch App
//
//  Created by KimTaeHyung on 2023/07/11.
//

import SwiftUI

struct GuideView: View {
    let swingList: SwingList
    var body: some View {
        Image(systemName: swingList.gifImage)
            .resizable()
    }
}

struct GuideView_Previews: PreviewProvider {
    static var previews: some View {
        GuideView(swingList: swingLists[0])
    }
}
