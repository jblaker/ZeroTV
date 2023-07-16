//
//  StreamingGroup.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import Foundation

struct StreamingGroup: Identifiable {
    var id: UUID
    var name: String
    var isFavorite: Bool
    var streams = [StreamInfo]()
    var posterURL: URL?
}
