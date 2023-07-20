//
//  BookmarksList.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/19/23.
//

import SwiftUI

struct BookmarksList: View {
    @EnvironmentObject var modelData: ModelData

    var body: some View {
        ZStack {
            gradient
            NavigationView {
                List {
                    ForEach(modelData.bookmarks) { bookmark in
                        NavigationLink {
                            StreamInfoView(streamInfo: bookmark)
                        } label: {
                            Text(bookmark.name)
                        }
                    }
                }
                .navigationTitle("Bookmarks")
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct BookmarksList_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksList()
            .environmentObject(ModelData())
    }
}
