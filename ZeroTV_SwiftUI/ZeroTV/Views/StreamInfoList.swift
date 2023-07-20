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

    var body: some View {
        ZStack {
            gradient
            NavigationView {
                List {
                    ForEach(streamingGroup.streams) { stream in
                        NavigationLink {
                            StreamInfoView(streamInfo: stream)
                        } label: {
                            if (stream.isBookmarked(modelData: modelData)) {
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
