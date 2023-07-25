//
//  StreamInfoList.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import SwiftUI

struct StreamInfoList: View {
    @EnvironmentObject var modelData: ModelData

    @State var streamingGroup: StreamingGroup

    var body: some View {
        ZStack {
            gradient
            NavigationView {
                List {
                    ForEach(modelData.selectedGroup?.filteredStreams ?? [StreamInfo]()) { stream in
                        NavigationLink {
                            StreamInfoView(streamInfo: stream)
                        } label: {
                            if (stream.isBookmarked(modelData: modelData)) {
                                Label(stream.name, systemImage: "bookmark.fill")
                                    .foregroundColor(stream.isWatched(modelData: modelData) ? .secondary : .primary)
                            } else {
                                Text(stream.name)
                                    .foregroundColor(stream.isWatched(modelData: modelData) ? .secondary : .primary)
                            }
                        }
                    }
                }
                .navigationTitle(streamingGroup.name)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            streamingGroup.filterDuplicates(modelData: modelData) { streamingGroup in
                self.streamingGroup = streamingGroup
                modelData.selectedGroup = streamingGroup
            }
        }
    }
}

struct StreamInfoList_Previews: PreviewProvider {
    static var previews: some View {
        StreamInfoList(streamingGroup: ModelData().streamingGroups[0])
    }
}
