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
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        BookmarkButton(streamInfo: streamInfo)
//                    }
                    Button {
                        showingOptions.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }

                }
            }
            .alert("Options", isPresented: $showingOptions) {
//                Button(streamInfo.isBookmarked(modelData: modelData) ? "Remove Bookmark" : "Add Bookmark", role: ButtonRole.destructive) { }
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
