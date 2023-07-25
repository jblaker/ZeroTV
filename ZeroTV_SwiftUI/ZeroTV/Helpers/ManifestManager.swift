//
//  ManifestManager.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/20/23.
//

import Foundation

struct ManifestManager {
    
    static func fetchManifestData(_ url: URL) -> (Data?, Error?) {
        return (nil, nil)
    }
    
    static func parseManifestData(_ data: Data) -> [StreamingGroup] {
        guard let manifest = String(data: data, encoding: .utf8) else {
            return []
        }
        
        let lines = manifest.components(separatedBy: .newlines)
        var streamingGroups = [String:StreamingGroup]()
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
                        if let _ = streamingGroups[groupName] {
                        } else {
                            let group = StreamingGroup(id: UUID(), name: groupName, isFavorite: false, streams: [])
                            streamingGroups[groupName] = group
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
                    if let currentGroupName = currentGroupName, let _ = streamingGroups[currentGroupName] {
                        streamingGroups[currentGroupName]!.streams.append(streamInfo)
                    }
                }
            }

        }

        return streamingGroups.map { $0.value }.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending
        }
    }
    
}
