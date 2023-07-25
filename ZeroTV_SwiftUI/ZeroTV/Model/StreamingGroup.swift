//
//  StreamingGroup.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import Foundation

struct StreamingGroup: Identifiable, Codable, Hashable {
    static func == (lhs: StreamingGroup, rhs: StreamingGroup) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: UUID
    var name: String
    var isFavorite: Bool
    var streams = [StreamInfo]()
}
