//
//  BookmarkManager.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/20/23.
//

import Foundation

struct BookmarkManager {
    
    static func loadBookmarks() -> [StreamInfo] {
        let result = CacheManager.cached(streamsListWithFilename: "bookmarks")
        guard let bookmarks = result.0 else {
            return [StreamInfo]()
        }

        return bookmarks
    }
    
    static func cacheBookmarks(_ bookmarks: [StreamInfo]) {
        if let error = CacheManager.cache(streamsList: bookmarks, filename: "bookmarks") {
            print(error)
        }
    }
    
}
