//
//  StreamInfoView.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/19/23.
//

import SwiftUI

struct StreamInfoView: View {
    @EnvironmentObject var modelData: ModelData
    @State var showingOptions = false
    
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
                    Button {
                        showingOptions.toggle()
                    } label: {
                        Label("Stream Options", systemImage: "slider.horizontal.3")
                            .labelStyle(.iconOnly)
                    }

                }
            }
            .alert("Options", isPresented: $showingOptions) {
                BookmarkButton(streamInfo: streamInfo)
                WatchedButton(streamInfo: streamInfo)
                Button("Cancel", role: .cancel) { }
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
