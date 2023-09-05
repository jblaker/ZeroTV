//
//  M3U8Manager.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/23/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface M3U8Manager : NSObject

+ (void)fetchManifest:(void (^)(NSData * _Nullable data, NSError * _Nullable error))completionHandler;

+ (NSDictionary *)parseManifest:(NSData *)manifestData;

@end

NS_ASSUME_NONNULL_END
