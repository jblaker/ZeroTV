//
//  BookmarkManager.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 3/12/22.
//

#import "BookmarkManager.h"
#import "StreamInfo.h"
#import "CacheManager.h"

NSString * const kBookmarksDataCache = @"bookmarks";

@implementation BookmarkManager

+ (NSArray<StreamInfo *> *)bookmarks
{
    NSMutableArray *bookmarks = @[].mutableCopy;
    for (NSData *data in [CacheManager cachedArrayNamed:kBookmarksDataCache])
    {
        StreamInfo *archivedStream = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [bookmarks addObject:archivedStream];
    }
    return bookmarks;
}

+ (void)addBookmarkForStream:(StreamInfo *)stream
{
    NSArray *bookmarks = [CacheManager cachedArrayNamed:kBookmarksDataCache];
    NSMutableArray *updatedBookmarks = bookmarks.mutableCopy;
    if (!updatedBookmarks)
    {
        updatedBookmarks = @[].mutableCopy;
    }
    
    NSData *bookmarkData = [NSKeyedArchiver archivedDataWithRootObject:stream];
    [updatedBookmarks addObject:bookmarkData];
    
    BOOL success = [CacheManager cacheArray:updatedBookmarks filename:kBookmarksDataCache];
    
    NSLog(@"Did update bookmarks : %@", success ? @"YES" : @"NO");
}

+ (void)removeBookmarForStream:(StreamInfo *)stream
{
    NSArray *bookmarks = [CacheManager cachedArrayNamed:kBookmarksDataCache];
    NSMutableArray *updatedBookmarks = bookmarks.mutableCopy;
    
    for (NSData *data in bookmarks)
    {
        StreamInfo *archivedStream = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([archivedStream isEqual:stream])
        {
            [updatedBookmarks removeObject:data];
            break;
        }
    }
    
    BOOL success = [CacheManager cacheArray:updatedBookmarks filename:kBookmarksDataCache];
    
    NSLog(@"Did update bookmarks : %@", success ? @"YES" : @"NO");
}

+ (BOOL)streamIsBookmarked:(StreamInfo *)stream
{
    NSArray *bookmarks = [CacheManager cachedArrayNamed:kBookmarksDataCache];
    if (bookmarks)
    {
        for (NSData *data in bookmarks)
        {
            StreamInfo *archivedStream = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            if ([archivedStream isEqual:stream])
            {
                return YES;
                break;
            }
        }
    }
    return NO;
}

@end
