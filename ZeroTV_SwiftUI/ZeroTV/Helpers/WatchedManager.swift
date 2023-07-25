//
//  WatchedManager.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/25/23.
//

import Foundation

struct WatchedManager {
    
    static func loadWatched() -> [StreamInfo] {
        let result = CacheManager.cached(streamsListWithFilename: "watched")
        guard let bookmarks = result.0 else {
            return [StreamInfo]()
        }

        return bookmarks
    }
    
    static func cacheWatched(_ bookmarks: [StreamInfo]) {
        if let error = CacheManager.cache(streamsList: bookmarks, filename: "watched") {
            print(error)
        }
    }
    
}
