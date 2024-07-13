//
//  CacheManager.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/24/20.
//

#import <Foundation/Foundation.h>

extern NSString * _Nonnull const kCachedSubFilename;
extern NSString * _Nonnull const kCachedManifestFilename;

NS_ASSUME_NONNULL_BEGIN

@interface CacheManager : NSObject

+ (NSString *)cacheDirectoryPath;

+ (NSError *)cacheData:(NSData *)data filename:(NSString *)filename;

+ (NSData *)cachedDataNamed:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
