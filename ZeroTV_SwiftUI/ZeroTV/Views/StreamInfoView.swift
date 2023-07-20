//
//  StreamInfoView.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/19/23.
//

import SwiftUI

struct StreamInfoView: View {
    @EnvironmentObject var modelData: ModelData
    
    var streamInfo: StreamInfo
    var streamingGroupIndex: Int {
        modelData.streamingGroups.firstIndex(where: {
            $0 == modelData.selectedGroup!
        })!
    }
    var streamInfoIndex: Int {
        modelData.streamingGroups[streamingGroupIndex].streams.firstIndex(where: {
            $0.name == streamInfo.name
        })!
    }

    var body: some View {
        ZStack {
            gradient
            NavigationView {
                List {
                    
                }
                .navigationTitle(streamInfo.name)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        BookmarkButton(isBookmarked: $modelData.streamingGroups[streamingGroupIndex].streams[streamInfoIndex].isBookmarked)
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct StreamInfoView_Previews: PreviewProvider {
    static var previews: some View {
        StreamInfoView(streamInfo: ModelData().streamingGroups.first!.streams.first!)
    }
}
