//
//  DownloadUploadManager.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/23/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadUploadManager : NSObject

+ (void)fetchSubtitleFileData:(NSURL *)url completionHandler:(void (^)(NSData * _Nullable data, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
