//
//  BookmarkButton.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/20/23.
//

import SwiftUI

struct BookmarkButton: View {
    @EnvironmentObject var modelData: ModelData
    
    var streamInfo: StreamInfo
    var isBookmarked: Bool {
        return streamInfo.isBookmarked(modelData: modelData)
    }
    var streamInfoIndex: Int {
        return modelData.bookmarks.firstIndex {
            $0 == streamInfo
        } ?? -1
    }
    var body: some View {
        Button(action: {
            if (isBookmarked) {
                modelData.bookmarks.remove(at: streamInfoIndex)
            } else {
                modelData.bookmarks.append(streamInfo)
            }
            if let error = CacheManager.cache(streamsList: modelData.bookmarks, filename: "bookmarks") {
                print(error)
            }
            
        }) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
        }
    }
}

struct BookmarkButton_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkButton(streamInfo: ModelData().streamingGroups.first!.streams.first!)
    }
}
