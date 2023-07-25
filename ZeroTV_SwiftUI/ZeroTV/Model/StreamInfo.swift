//
//  StreamInfo.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import Foundation

struct StreamInfo: Identifiable, Codable, Hashable {
    static func == (lhs: StreamInfo, rhs: StreamInfo) -> Bool {
        return lhs.name == rhs.name
    }

    var id: UUID
    var name: String
    var streamURL: String
    
    func isBookmarked(modelData: ModelData) -> Bool {
        let match = modelData.bookmarks.filter {
            $0 == self
        }.first
        guard let _ = match else {
            return false
        }
        return true
    }
    
    func isWatched(modelData: ModelData) -> Bool {
        let match = modelData.watched.filter {
            $0 == self
        }.first
        guard let _ = match else {
            return false
        }
        return true
    }
}
