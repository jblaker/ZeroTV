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
        ZStack {
            gradient
            NavigationView {
                List {
                    NavigationLink {
                        FavoritesList()
                    } label: {
                        Text("Favorites")
                    }
                    if modelData.bookmarks.count > 0 {
                        NavigationLink {
                            BookmarksList()
                        } label: {
                            Text("Bookmarks")
                        }
                    }
                    ForEach(modelData.streamingGroups) { streamingGroup in
                        NavigationLink {
                            StreamInfoList(streamingGroup: streamingGroup)
                        } label: {
                            Text(streamingGroup.name)
                        }
                    }
                }
                .navigationTitle("Categories")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Last updated \(Text(modelData.lastUpdatedDate, style: .date))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                print("refresh!")
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct StreamingGroupList_Previews: PreviewProvider {
    static var previews: some View {
        StreamingGroupList()
            .environmentObject(ModelData())
    }
}
