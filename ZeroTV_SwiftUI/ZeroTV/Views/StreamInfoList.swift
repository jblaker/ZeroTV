//
//  StreamInfoList.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import SwiftUI

struct StreamInfoList: View {
    @EnvironmentObject var modelData: ModelData

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
        NavigationView {
            List {
                ForEach(streams) { stream in
                    NavigationLink {
                        
                    } label: {
                        Text(stream.name)
                    }
                }
            }
            .navigationTitle(streamingGroup.name)
        }
    }
}

struct StreamInfoList_Previews: PreviewProvider {
    static var previews: some View {
        StreamInfoList(streamingGroup: ModelData().streamingGroups[0])
    }
}
