//
//  OpenSubtitlesAdapter.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/23/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenSubtitlesAdapter : NSObject

+ (void)subtitleSearch:(NSString *)query completionHandler:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable  error))completionHandler;

+ (void)subtitleDownload:(NSDictionary *)dictionary completionHandler:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completionHandler;

+ (NSArray *)englishSubtitlesFromSearchResponse:(NSDictionary *)searchResponse;

@end

NS_ASSUME_NONNULL_END
