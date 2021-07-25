//
//  EpisodeManager.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/26/20.
//

#import <Foundation/Foundation.h>

@class StreamInfo;

NS_ASSUME_NONNULL_BEGIN

@interface EpisodeManager : NSObject

+ (void)episodeDidComplete:(StreamInfo *)episode withPlaybackPosition:(float)playbackPosition;

+ (void)markAsWatched:(StreamInfo *)episode;

+ (void)markAsUnwatched:(StreamInfo *)episode;

+ (BOOL)episodeWasWatched:(StreamInfo *)episode;

+ (void)saveProgressForEpisode:(StreamInfo *)episode withPlaybackTime:(int)playbackTime;

+ (NSNumber * _Nullable)progressForEpisode:(StreamInfo *)episode;

@end

NS_ASSUME_NONNULL_END
