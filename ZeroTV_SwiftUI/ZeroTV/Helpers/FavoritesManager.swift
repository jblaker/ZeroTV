//
//  FavoritesManager.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/20/23.
//

import Foundation

struct FavoritesManager {
    
    static func loadFavorites() -> [StreamingGroup] {
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
            let group = StreamingGroup(id: UUID(), name: name, isFavorite: true)
            favoritesGroups.append(group)
        }
        
        return favoritesGroups
    }
}
