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
                    ForEach(modelData.bookmarks) { bookmarks in
                        NavigationLink {
                            
                        } label: {
                            Text(bookmarks.name)
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
