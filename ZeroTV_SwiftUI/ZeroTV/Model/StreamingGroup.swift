//
//  StreamingGroup.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/14/23.
//

import Foundation
import SwiftUI

struct StreamingGroup: Identifiable, Codable, Hashable {
    static func == (lhs: StreamingGroup, rhs: StreamingGroup) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: UUID
    var name: String
    var isFavorite: Bool
    var streams = [StreamInfo]()
    var filteredStreams = [StreamInfo]()

    func filterDuplicates(modelData: ModelData, completion: @escaping (StreamingGroup) -> Void) {
        let groupIndex = modelData.streamingGroups.firstIndex {
            $0 == self
        }

        guard let groupIndex = groupIndex else {
            print("Couldn't determine index for group")
            completion(self)
            return
        }
        
        if modelData.streamingGroups[groupIndex].filteredStreams.count > 0 {
            completion(modelData.streamingGroups[groupIndex])
            return
        }

        var sortedStreams = streams.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending
        }
        
        var _filteredStreams = [StreamInfo]()
        
        DispatchQueue.global(qos: .background).sync {
            for stream in sortedStreams {
                
                if _filteredStreams.count == 0 {
                    _filteredStreams.append(stream)
                    continue
                }
                
                let matchingIndex = streamInfoBinarySearch(lowerBounds: 0, upperBounds: _filteredStreams.count-1, streamInfo: stream, filteredStreams: _filteredStreams, groupIndex: groupIndex)
                
                if matchingIndex == NSNotFound {
                    _filteredStreams.append(stream)
                } else {
                    // Add stream URL to StreamInfo's alternate streams array
                }
            }
            
            sortedStreams = _filteredStreams.sorted {
                $0.index < $1.index
            }
            
            DispatchQueue.main.async {
                let updatedGroup = StreamingGroup(id: self.id, name: self.name, isFavorite: self.isFavorite, streams: self.streams, filteredStreams: sortedStreams)
                modelData.streamingGroups[groupIndex] = updatedGroup
                
                let allCount = updatedGroup.streams.count
                let filteredCount = updatedGroup.filteredStreams.count
                print("Filtered out \(allCount - filteredCount) duplicate streams in \(self.name).")
                
                Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
                    completion(updatedGroup)
                }
                
            }
        }
    }
    
    func streamInfoBinarySearch(lowerBounds: Int, upperBounds: Int, streamInfo: StreamInfo, filteredStreams: [StreamInfo], groupIndex: Int) -> Int {
        
        if lowerBounds > upperBounds {
            return NSNotFound
        }
        
        let mid = lowerBounds + (upperBounds - lowerBounds) / 2
        
        let midStream = filteredStreams[mid]
        
        let comparison = streamInfo.name.compare(midStream.name)
        
        if comparison == .orderedSame {
            return mid
        }
        
        if comparison == .orderedAscending {
            return streamInfoBinarySearch(lowerBounds: lowerBounds, upperBounds: upperBounds-1, streamInfo: streamInfo, filteredStreams: filteredStreams, groupIndex: groupIndex)
        }
        
        return streamInfoBinarySearch(lowerBounds: mid+1, upperBounds: upperBounds, streamInfo: streamInfo, filteredStreams: filteredStreams, groupIndex: groupIndex)
    }
   
}
