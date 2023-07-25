//
//  CacheManager.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/17/23.
//

import Foundation

struct CacheManager {

    enum ErrorCode: Int {
        case Cache = 1000
        case Read = 1001
    }
    
    static func cacheDirectoryPath() -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        guard let path = paths.first else {
            return nil
        }
        return path
    }
    
    static func cacheURL(forFilename filename: String) -> URL? {
        let cacheDirectoryPath = CacheManager.cacheDirectoryPath() as? NSString
        guard let filePath = cacheDirectoryPath?.appendingPathComponent(filename), let filePathURL = URL(string: filePath) else {
            return nil
        }
        return filePathURL
    }
    
    // MARK: - Data Caching
    
    static func cache(data: Data, filename: String) -> Error? {
        guard let filePathURL = CacheManager.cacheURL(forFilename: filename) else {
            return NSError(domain: "CacheManager", code: ErrorCode.Cache.rawValue, userInfo: [NSLocalizedDescriptionKey:"Could not create file path for \(filename)"])
        }
        
        do {
            try data.write(to: filePathURL)
        } catch {
            return error
        }
        
        return nil
    }
    
    static func cachedData(filename: String) -> (Data?, Error?) {
        guard let filePathURL = CacheManager.cacheURL(forFilename: filename) else {
            return (nil, NSError(domain: "CacheManager", code: ErrorCode.Cache.rawValue, userInfo: [NSLocalizedDescriptionKey:"Could not create file path for \(filename)"]))
        }

        do {
            let result = try Data(contentsOf: filePathURL)
            return (result, nil)
        } catch {
            return (nil, error)
        }
    }
    
    // MARK: - Array Caching
    
    static func cache(streamsList: [StreamInfo], filename: String) -> Error? {
        do {
            let encoded = try JSONEncoder().encode(streamsList)
            UserDefaults.standard.set(encoded, forKey: filename)
            return nil
        } catch {
            return error
        }
    }
    
    static func cached(streamsListWithFilename filename: String) -> ([StreamInfo]?, Error?) {
        guard let data = UserDefaults.standard.object(forKey: filename) as? Data else {
            return (nil, nil)
        }
        do {
            let streamsList = try JSONDecoder().decode([StreamInfo].self, from: data)
            return (streamsList, nil)
        } catch {
            return (nil, error)
        }
    }

}
