//
//  StreamInfoList.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import SwiftUI

struct StreamInfoList: View {
    @EnvironmentObject var modelData: ModelData
    @State var showAlert = false

    var streamingGroup: StreamingGroup
    var streams: [StreamInfo] {
        if streamingGroup.isFavorite {
            if let vodGroup = modelData.vodGroup {
                return vodGroup.streams.filter {
                    $0.name.contains(streamingGroup.name)
                }.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == ComparisonResult.orderedDescending
                }
            }
            return [StreamInfo]()
        } else {
            return streamingGroup.streams
        }
    }

    var body: some View {
        ZStack {
            gradient
            NavigationView {
                List {
                    ForEach(streams) { stream in
                        NavigationLink {
                            StreamInfoView(streamInfo: stream)
                        } label: {
                            if (stream.isBookmarked) {
                                Label(stream.name, systemImage: "bookmark.fill")
                            } else {
                                Text(stream.name)
                            }
                        }
                    }
                }
                .navigationTitle(streamingGroup.name)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            modelData.selectedGroup = streamingGroup
        }
    }
}

struct StreamInfoList_Previews: PreviewProvider {
    static var previews: some View {
        StreamInfoList(streamingGroup: ModelData().streamingGroups[0])
    }
}
