//
//  BookmarkManager.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 3/12/22.
//

#import <Foundation/Foundation.h>

@protocol GenericStream;

NS_ASSUME_NONNULL_BEGIN

@interface BookmarkManager : NSObject

+ (NSArray <id<GenericStream>> * _Nullable)bookmarks;
+ (void)addBookmarkForStream:(id<GenericStream>)stream;
+ (void)removeBookmarkForStream:(id<GenericStream>)stream;
+ (BOOL)streamIsBookmarked:(id<GenericStream>)stream;

@end

NS_ASSUME_NONNULL_END
