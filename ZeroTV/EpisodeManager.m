//
//  EpisodeManager.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/26/20.
//

#import "EpisodeManager.h"
#import "StreamInfo.h"
#import "CacheManager.h"

float const kPlaybackCompletionTreshold = 0.75;
NSString * const kWatchedDataCache = @"watchedData";
NSString * const kProgressDataCache = @"progressData";

@implementation EpisodeManager

+ (void)episodeDidComplete:(StreamInfo *)episode withPlaybackPosition:(float)playbackPosition
{
    if (playbackPosition > kPlaybackCompletionTreshold)
    {
        [EpisodeManager markAsWatched:episode];
    }
}

+ (void)saveProgressForEpisode:(StreamInfo *)episode withPlaybackTime:(int)playbackTime
{
    if (!episode.isVOD)
    {
        return;
    }
    
    NSArray *epProgresses = [CacheManager cachedArrayNamed:kProgressDataCache];
    NSMutableArray *newProgresses = epProgresses.mutableCopy;
        
    if (!epProgresses)
    {
        newProgresses = @[].mutableCopy;
    }
    
    NSDictionary *progress = @{
        @"name":episode.name,
        @"progress":@(playbackTime)
    };
    
    BOOL updatedExisting = NO;
    int matchingIndex = -1;
    
    int counter = 0;
    
    for (NSDictionary *progress in epProgresses)
    {
        if ([progress[@"name"] isEqualToString:episode.name])
        {
            updatedExisting = YES;
            matchingIndex = counter;
        }
        counter += 1;
    }
    
    if (updatedExisting)
    {
        [newProgresses replaceObjectAtIndex:matchingIndex withObject:progress];
    }
    else
    {
        [newProgresses addObject:progress];
    }
    
    BOOL success = [CacheManager cacheArray:newProgresses filename:kProgressDataCache];
    
    NSLog(@"Did update episode progress : %@", success ? @"YES" : @"NO");
}

+ (void)markAsWatched:(StreamInfo *)episode
{
    NSMutableArray *watchedEps = [CacheManager cachedArrayNamed:kWatchedDataCache].mutableCopy;
        
    if (!watchedEps)
    {
        watchedEps = @[].mutableCopy;
    }
    
    if ([watchedEps indexOfObject:episode.name] == NSNotFound)
    {
        [watchedEps addObject:episode.name];
    }
    
    BOOL success = [CacheManager cacheArray:watchedEps filename:kWatchedDataCache];
    
    NSLog(@"Did update watched eps : %@", success ? @"YES" : @"NO");
}

+ (void)markAsUnwatched:(StreamInfo *)episode
{
    NSMutableArray *watchedEps = [CacheManager cachedArrayNamed:kWatchedDataCache].mutableCopy;
        
    if (!watchedEps)
    {
        watchedEps = @[].mutableCopy;
    }
    
    if ([watchedEps indexOfObject:episode.name] != NSNotFound)
    {
        [watchedEps removeObject:episode.name];
    }
    
    [CacheManager cacheArray:watchedEps filename:kWatchedDataCache];
}

+ (BOOL)episodeWasWatched:(StreamInfo *)episode
{
    NSArray *watchedEps = [CacheManager cachedArrayNamed:kWatchedDataCache];
    
    for (NSString *name in watchedEps)
    {
        if ([name isEqualToString:episode.name])
        {
            return YES;
        }
    }
    
    return NO;
}

+ (NSNumber *)progressForEpisode:(StreamInfo *)episode
{
    NSArray *epProgresses = [CacheManager cachedArrayNamed:kProgressDataCache];
        
    for (NSDictionary *progress in epProgresses)
    {
        if ([progress[@"name"] isEqualToString:episode.name])
        {
            return progress[@"progress"];
        }
    }
    
    return nil;
}

@end
