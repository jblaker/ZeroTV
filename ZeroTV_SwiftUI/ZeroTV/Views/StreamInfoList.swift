//
//  StreamInfoList.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import SwiftUI

struct StreamInfoList: View {
    var streamingGroup: StreamingGroup

    var body: some View {
        NavigationView {
            List {
                ForEach(streamingGroup.streams) { stream in
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
