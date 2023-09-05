//
//  BookmarkManager.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 3/12/22.
//

#import <Foundation/Foundation.h>

@class StreamInfo, Bookmark;

NS_ASSUME_NONNULL_BEGIN

@interface BookmarkManager : NSObject

+ (NSArray <Bookmark *> * _Nullable)bookmarks;
+ (void)addBookmarkForStream:(StreamInfo *)stream;
+ (void)removeBookmarkForStream:(StreamInfo *)stream;
+ (BOOL)streamIsBookmarked:(StreamInfo *)stream;

@end

NS_ASSUME_NONNULL_END
