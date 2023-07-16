//
//  StreamingGroupList.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import SwiftUI

struct StreamingGroupList: View {
    @EnvironmentObject var modelData: ModelData

    var body: some View {
        NavigationView {
            List {
                ForEach(modelData.streamingGroups.sorted{ $0.name.localizedCaseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending }) { streamingGroup in
                    NavigationLink {
                        StreamInfoList(streamingGroup: streamingGroup)
                    } label: {
                        Text(streamingGroup.name)
                    }
                }
            }
            .navigationTitle("Categories")
        }
    }
}

struct StreamingGroupList_Previews: PreviewProvider {
    static var previews: some View {
        StreamingGroupList()
            .environmentObject(ModelData())
    }
}
