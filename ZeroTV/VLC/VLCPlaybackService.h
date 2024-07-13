//
//  VLCPlaybackService.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import <Foundation/Foundation.h>

@import TVVLCKit;

@class VLCPlaybackService;

NS_ASSUME_NONNULL_BEGIN

@protocol VLCPlaybackServiceDelegate <NSObject>

@optional
- (void)playbackPositionUpdated:(VLCPlaybackService *)playbackService;
- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
             forPlaybackService:(VLCPlaybackService *)playbackService;
- (void)prepareForMediaPlayback:(VLCPlaybackService *)playbackService;

@end

@interface VLCPlaybackService : NSObject

+ (instancetype)sharedInstance;

- (void)startPlayback;
- (void)stopPlayback;
- (void)playPause;
- (void)play;
- (void)pause;
- (void)jumpForward:(NSTimeInterval)interval;
- (void)jumpBackward:(NSTimeInterval)interval;

- (float)playbackPosition;

- (VLCTime *)playedTime;
- (VLCTime *)remainingTime;
- (NSInteger)mediaDuration;

- (void)playMedia:(VLCMedia *)media hasSubs:(BOOL)hasSubs completion:(void (^ __nullable)(BOOL success, float playbackPosition))completion;

@property (nonatomic, weak) id<VLCPlaybackServiceDelegate> delegate;
@property (nonatomic, strong, nullable) UIView *videoOutputView;
@property (nonatomic, strong, readonly) VLCMediaPlayer *mediaPlayer;

- (void)applyCachedSubtitle;
- (void)clearSubtitle;

@end

NS_ASSUME_NONNULL_END
