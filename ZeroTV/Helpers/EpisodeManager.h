//
//  EpisodeManager.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/26/20.
//

#import <Foundation/Foundation.h>

@class Progress;
@protocol GenericStream;

NS_ASSUME_NONNULL_BEGIN

@interface EpisodeManager : NSObject

+ (void)episodeDidComplete:(id<GenericStream>)episode withPlaybackPosition:(float)playbackPosition;

+ (void)markAsWatched:(id<GenericStream>)episode;

+ (void)markAsUnwatched:(id<GenericStream>)episode;

+ (BOOL)episodeWasWatched:(id<GenericStream>)episode;

+ (void)saveProgressForEpisode:(id<GenericStream>)episode withPlaybackTime:(int)playbackTime;

+ (int)progressForEpisode:(id<GenericStream>)episode;

@end

NS_ASSUME_NONNULL_END
