//
//  BookmarkManager.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 3/12/22.
//

#import <Foundation/Foundation.h>

@class StreamInfo;

NS_ASSUME_NONNULL_BEGIN

@interface BookmarkManager : NSObject

+ (NSArray <StreamInfo *> *)bookmarks;
+ (void)addBookmarkForStream:(StreamInfo *)stream;
+ (void)removeBookmarForStream:(StreamInfo *)stream;
+ (BOOL)streamIsBookmarked:(StreamInfo *)stream;

@end

NS_ASSUME_NONNULL_END
