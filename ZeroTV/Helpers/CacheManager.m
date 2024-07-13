//
//  CacheManager.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/24/20.
//

#import "CacheManager.h"

NSString * const kCachedSubFilename = @"cached.webvtt";
NSString * const kCachedManifestFilename = @"manifest.m3u8";

@implementation CacheManager

+ (NSString *)cacheDirectoryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

+ (NSError *)cacheData:(NSData *)data filename:(NSString *)filename
{
    NSString *cacheDirectoryPath = [CacheManager cacheDirectoryPath];
    NSString *filePath = [cacheDirectoryPath stringByAppendingPathComponent:filename];
    
    NSError *error;
    [data writeToFile:filePath options:NSDataWritingAtomic error:&error];
    
    return error;
}

+ (NSData *)cachedDataNamed:(NSString *)name
{
    NSString *cacheDirPath = [CacheManager cacheDirectoryPath];
    NSString *filePath = [cacheDirPath stringByAppendingPathComponent:name];
    return [NSData dataWithContentsOfFile:filePath];
}

@end
