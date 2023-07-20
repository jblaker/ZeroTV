//
//  CacheManager.swift
//  ZeroTV
//
//  Created by Jeremy Blaker on 7/17/23.
//

import Foundation

struct CacheManager {
    
    let ErrorDomain = "CacheManager"
    
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
    
    static func cache(array: [AnyHashable], filename: String) -> Error? {
        guard let filePathURL = CacheManager.cacheURL(forFilename: filename) else {
            return NSError(domain: "CacheManager", code: ErrorCode.Cache.rawValue, userInfo: [NSLocalizedDescriptionKey:"Could not create file path for \(filename)"])
        }
    
        do {
            let array = array as NSArray
            try array.write(to: filePathURL)
        } catch {
            return error
        }

        return nil
    }
    
    static func cached(dataWithFilename filename: String) -> (Data?, Error?) {
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
    
    static func cached(arrayWithFilename filename: String) -> ([AnyHashable]?, Error?) {
        guard let filePathURL = CacheManager.cacheURL(forFilename: filename) else {
            return (nil, NSError(domain: "CacheManager", code: ErrorCode.Cache.rawValue, userInfo: [NSLocalizedDescriptionKey:"Could not create file path for \(filename)"]))
        }

        if let result = NSArray(contentsOf: filePathURL) as? [AnyHashable] {
            return (result, nil)
        } else {
            return (nil, NSError(domain: "CacheManager", code: ErrorCode.Read.rawValue))
        }
    }
}
