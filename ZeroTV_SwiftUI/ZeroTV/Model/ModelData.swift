//
//  ModelData.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import Foundation

let kLineInfoPrefix = "#EXTINF:"

final class ModelData: ObservableObject {
    @Published var streamingGroupDict = [String:StreamingGroup]()
    @Published var favorites = [StreamingGroup]()
    var streamingGroups: [StreamingGroup] {
        streamingGroupDict.map { $0.value }
    }
    
    init() {
        streamingGroupDict = load()
        favorites = loadFavorites()
    }
}

func load() -> [String:StreamingGroup] {
    guard let path = Bundle.main.url(forResource: "iptv", withExtension: "m3u8") else {
        return [:]
    }
    
    var data: Data?
    do {
        data = try Data(contentsOf: path)
    } catch {
        print(error)
        return [:]
    }

    guard let data = data, let manifest = String(data: data, encoding: .utf8) else {
        return [:]
    }
    
    let lines = manifest.components(separatedBy: .newlines)
    var streamingGroups = [String:StreamingGroup]()
//    var currentGroup: StreamingGroup?
    var currentGroupName: String?
    var streamName: String?
    
    for line in lines {
        if line.hasPrefix(kLineInfoPrefix) {
            do {
                let regex = try NSRegularExpression(pattern: "group-title=\"(.*?)\"")
                let range = NSRange(location: 0, length: line.utf16.count)
                let matches = regex.matches(in: line, range: range)
                
                if let match = matches.first {
                    guard let matchRange = Range(match.range(at: 1), in: line) else {
                        continue
                    }
                    let groupName = String(line[matchRange])
                    currentGroupName = groupName
                    if let group = streamingGroups[groupName] {
//                        currentGroup = group
                    } else {
                        let group = StreamingGroup(id: UUID(), name: groupName, isFavorite: false, streams: [])
                        streamingGroups[groupName] = group
//                        currentGroup = group
                    }
                }
            } catch  {
                print("Regex Error: \(error)")
            }
            
            let lineParts = line.components(separatedBy: ",")
            streamName = lineParts.last
        }
        
        if let streamName = streamName {
            if line.hasPrefix("https:") || line.hasPrefix("http:") {
                let streamInfo = StreamInfo(id: UUID(), name: streamName, streamURL: line)
                if let currentGroupName = currentGroupName {
                    streamingGroups[currentGroupName]!.streams.append(streamInfo)
                }
            }
        }

    }

    return streamingGroups
}

func loadFavorites() -> [StreamingGroup] {
    guard let path = Bundle.main.url(forResource: "Config", withExtension: "plist") else {
        return []
    }
    
    var favoriteShows: [[String:Any]]?

    do {
        let data = try Data(contentsOf: path)
        guard let config = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String:Any], let _favoriteShows = config["FavoriteShows"] as? [[String:Any]] else
        {
            return []
        }
        favoriteShows = _favoriteShows
    } catch {
        print(error)
    }
    
    guard let favoriteShows = favoriteShows else {
        return []
    }
    
    var favoritesGroups = [StreamingGroup]()
    
    for show in favoriteShows {
        guard let name = show["name"] as? String, let isActive = show["active"] as? Bool else {
            continue
        }
        if !isActive {
            continue
        }
        var posterURL: URL?
        if let posterURLStr = show["posterURL"] as? String {
            posterURL = URL(string: posterURLStr)
        }
        let group = StreamingGroup(id: UUID(), name: name, isFavorite: true, posterURL: posterURL)
        favoritesGroups.append(group)
    }
    
    return favoritesGroups
}
