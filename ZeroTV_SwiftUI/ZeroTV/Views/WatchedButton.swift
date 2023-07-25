//
//  WatchedButton.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/25/23.
//

import SwiftUI

struct WatchedButton: View {
    @EnvironmentObject var modelData: ModelData
    
    var streamInfo: StreamInfo
    var isWatched: Bool {
        return streamInfo.isWatched(modelData: modelData)
    }
    var streamInfoIndex: Int {
        return modelData.watched.firstIndex {
            $0 == streamInfo
        } ?? -1
    }
    var body: some View {
        Button(isWatched ? "Mark as Unwatched" : "Mark as Watched") {
            if (isWatched) {
                modelData.watched.remove(at: streamInfoIndex)
            } else {
                modelData.watched.append(streamInfo)
            }
            WatchedManager.cacheWatched(modelData.watched)
        }
    }
}

struct WatchedButton_Previews: PreviewProvider {
    static var previews: some View {
        WatchedButton(streamInfo: ModelData().streamingGroups.first!.streams.first!)
    }
}
