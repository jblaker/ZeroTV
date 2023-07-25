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
        Button(isBookmarked ? "Remove Bookmark" : "Add Bookmark") {
            if (isBookmarked) {
                modelData.bookmarks.remove(at: streamInfoIndex)
            } else {
                modelData.bookmarks.append(streamInfo)
            }
            BookmarkManager.cacheBookmarks(modelData.bookmarks)
        }
    }
}

struct BookmarkButton_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkButton(streamInfo: ModelData().streamingGroups.first!.streams.first!)
    }
}
