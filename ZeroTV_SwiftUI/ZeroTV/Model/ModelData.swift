//
//  ModelData.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import Foundation

let kLineInfoPrefix = "#EXTINF:"

final class ModelData: ObservableObject {
    @Published var streamingGroups: [StreamingGroup]
    @Published var favorites: [StreamingGroup]
    @Published var lastUpdatedDate = Date()
    @Published var bookmarks: [StreamInfo]
    @Published var selectedGroup: StreamingGroup?
    
    var vodGroup: StreamingGroup? {
        return streamingGroups.filter {
            $0.name == "TV VOD"
        }.first
    }

    init() {
        streamingGroups = loadStreamingGroups()
        favorites = FavoritesManager.loadFavorites()
        bookmarks = BookmarkManager.loadBookmarks()
    }
}

func loadStreamingGroups() -> [StreamingGroup] {
    // Do we have a cached manifest?
    let result = CacheManager.cachedData(filename: "iptv")
    if let error = result.1 {
        print(error)
    }
    if let data = result.0 {
        let groups = ManifestManager.parseManifestData(data)
        return groups
    }
    
    guard let path = Bundle.main.url(forResource: "iptv", withExtension: "m3u8") else {
        return []
    }

    do {
        let data = try Data(contentsOf: path)
        let groups = ManifestManager.parseManifestData(data)
        if let error = CacheManager.cache(data: data, filename: "iptv") {
            print(error)
        }
        return groups
    } catch {
        print(error)
        return []
    }
}

