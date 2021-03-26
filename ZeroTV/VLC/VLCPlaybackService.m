//
//  VLCPlaybackService.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "VLCPlaybackService.h"
#import "VLCConstants.h"
#import "CacheManager.h"

@import TVVLCKit;

typedef NS_ENUM(NSUInteger, VLCAspectRatio) {
    VLCAspectRatioDefault = 0,
    VLCAspectRatioFillToScreen,
    VLCAspectRatioFourToThree,
    VLCAspectRatioSixteenToNine,
    VLCAspectRatioSixteenToTen,
};

@interface VLCPlaybackService ()<VLCMediaPlayerDelegate, VLCMediaDelegate>

@property (nonatomic, strong) VLCMediaList *mediaList;
@property (nonatomic, assign) BOOL playerIsSetup;
@property (nonatomic, assign) BOOL sessionWillRestart;
@property (nonatomic, assign) BOOL mediaWasJustStarted;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL currentMediaHasTrackToChooseFrom;
@property (nonatomic, assign) BOOL currentMediaHasChapters;
@property (nonatomic, assign) BOOL needsMetadataUpdate;
@property (nonatomic, strong) NSLock *playbackSessionManagementLock;
@property (nonatomic, strong) UIView *actualVideoOutputView;
@property (nonatomic, strong) VLCMediaListPlayer *listPlayer;
@property (nonatomic, strong) VLCMediaPlayer *mediaPlayer;
@property (nonatomic, copy) void (^playbackCompletion)(BOOL success, float playbackPosition);
@property (nonatomic, strong) NSDictionary *mediaOptionsDictionary;
@property (nonatomic, strong) VLCRendererItem *renderer;
@property (nonatomic, assign) VLCAspectRatio currentAspectRatio;
@property (nonatomic, assign) BOOL isInFillToScreen;
@property (nonatomic, assign) BOOL hasSubs;
@property (nonatomic, strong) UIView *videoOutputViewWrapper;

// TODO: Implement this?
//@property (nonatomic, strong) VLCRemoteControlService *remoteControlService;

@end

@implementation VLCPlaybackService

+ (instancetype)sharedInstance
{
    static VLCPlaybackService *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [VLCPlaybackService new];
    });

    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _playbackSessionManagementLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)playMediaList:(VLCMediaList *)mediaList hasSubs:(BOOL)hasSubs completion:(void (^ __nullable)(BOOL success, float playbackPosition))completion
{
    self.playbackCompletion = completion;
    self.mediaList = mediaList;
    self.hasSubs = hasSubs;

    self.sessionWillRestart = self.playerIsSetup;
    self.playerIsSetup ? [self stopPlayback] : [self startPlayback];
}

- (void)startPlayback
{
    if (self.playerIsSetup)
    {
        NSLog(@"%s: player is already setup, bailing out", __PRETTY_FUNCTION__);
        return;
    }

    BOOL ret = [self.playbackSessionManagementLock tryLock];
    if (!ret)
    {
        NSLog(@"%s: locking failed", __PRETTY_FUNCTION__);
        return;
    }

    if (!self.mediaList)
    {
        NSLog(@"%s: no URL and no media list set, stopping playback", __PRETTY_FUNCTION__);
        [self.playbackSessionManagementLock unlock];
        [self stopPlayback];
        return;
    }

    /* video decoding permanently fails if we don't provide a UIView to draw into on init
     * hence we provide one which is not attached to any view controller for off-screen drawing
     * and disable video decoding once playback started */
    self.actualVideoOutputView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.actualVideoOutputView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.actualVideoOutputView.autoresizesSubviews = YES;

    self.listPlayer = [[VLCMediaListPlayer alloc] initWithDrawable:self.actualVideoOutputView];

    /* to enable debug logging for the playback library instance, switch the boolean below
     * note that the library instance used for playback may not necessarily match the instance
     * used for media discovery or thumbnailing */
    self.listPlayer.mediaPlayer.libraryInstance.debugLogging = NO;

    self.mediaPlayer = self.listPlayer.mediaPlayer;
    [self.mediaPlayer setDelegate:self];

    VLCMedia *media = [self.mediaList mediaAtIndex:0];
    [media parseWithOptions:VLCMediaParseNetwork];
    media.delegate = self;
    [media addOptions:self.mediaOptionsDictionary];

    [self.listPlayer setMediaList:self.mediaList];

    [self.listPlayer setRepeatMode:VLCDoNotRepeat];

    [self.playbackSessionManagementLock unlock];

    [self playNewMedia];
}


- (void)playNewMedia
{
    BOOL ret = [self.playbackSessionManagementLock tryLock];
    if (!ret)
    {
        NSLog(@"%s: locking failed", __PRETTY_FUNCTION__);
        return;
    }

    self.mediaWasJustStarted = YES;

    [self.mediaPlayer addObserver:self forKeyPath:@"time" options:0 context:nil];
    [self.mediaPlayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];

    [self.mediaPlayer setRendererItem:self.renderer];

    [self.listPlayer playItemAtNumber:@(0)];

    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
    {
        [self.delegate prepareForMediaPlayback:self];
    }

    self.currentAspectRatio = VLCAspectRatioDefault;
    self.mediaPlayer.videoAspectRatio = NULL;
    self.mediaPlayer.videoCropGeometry = NULL;

    //[[self remoteControlService] subscribeToRemoteCommands];

    if (self.hasSubs)
    {
        [self applyCachedSubtitle];
    }

    self.playerIsSetup = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:kVLCPlaybackServicePlaybackDidStart object:self];
    [self.playbackSessionManagementLock unlock];
}

- (void)applyCachedSubtitle
{
    NSString *cacheDirPath = [CacheManager cacheDirectoryPath];
    NSString *cachedSubPath = [cacheDirPath stringByAppendingPathComponent:kCachedSubFilename];
    
    /* this could be a path or an absolute string - let's see */
    NSURL *subtitleURL = [NSURL URLWithString:cachedSubPath];
    if (!subtitleURL || !subtitleURL.scheme)
    {
        subtitleURL = [NSURL fileURLWithPath:cachedSubPath];
    }
    if (subtitleURL)
    {
        NSLog(@"Using sub at %@", subtitleURL.absoluteString);
        [self.mediaPlayer addPlaybackSlave:subtitleURL type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];
    }
}

- (void)clearSubtitle
{
    if (self.mediaPlayer.videoSubTitlesIndexes.count > 0)
    {
        self.mediaPlayer.currentVideoSubTitleIndex = [self.mediaPlayer.videoSubTitlesIndexes[0] intValue];
    }
}

- (void)stopPlayback
{
    BOOL ret = [self.playbackSessionManagementLock tryLock];
    self.isInFillToScreen = NO; // reset _isInFillToScreen after playback is finished
    if (!ret)
    {
        NSLog(@"%s: locking failed", __PRETTY_FUNCTION__);
        return;
    }

    if (self.mediaPlayer)
    {
        @try {
            [self.mediaPlayer removeObserver:self forKeyPath:@"time"];
            [self.mediaPlayer removeObserver:self forKeyPath:@"remainingTime"];
        }
        @catch (NSException *exception) {
            NSLog(@"we weren't an observer yet");
        }

        if (self.mediaPlayer.media)
        {
            [self.mediaPlayer pause];
            [self.mediaPlayer stop];
        }

        if (self.playbackCompletion)
        {
            BOOL finishedPlaybackWithError = false;
            if (self.mediaPlayer.state == VLCMediaPlayerStateStopped && self.mediaPlayer.media != nil)
            {
                // Since VLCMediaPlayerStateError is sometimes not matched with a valid media.
                // This checks for decoded Audio & Video blocks.
                finishedPlaybackWithError = (self.mediaPlayer.media.numberOfDecodedAudioBlocks == 0)
                                             && (self.mediaPlayer.media.numberOfDecodedVideoBlocks == 0);
            }
            else
            {
                finishedPlaybackWithError = self.mediaPlayer.state == VLCMediaPlayerStateError;
            }
            finishedPlaybackWithError = finishedPlaybackWithError && !self.sessionWillRestart;

            self.playbackCompletion(!finishedPlaybackWithError, self.playbackPosition);
        }

        self.mediaPlayer = nil;
        self.listPlayer = nil;
    }
    if (!self.sessionWillRestart)
    {
        self.mediaList = nil;
    }
    self.playerIsSetup = NO;

    //[[self remoteControlService] unsubscribeFromRemoteCommands];

    [self.playbackSessionManagementLock unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:kVLCPlaybackServicePlaybackDidStop object:self];
    if (self.sessionWillRestart)
    {
        self.sessionWillRestart = NO;
        [self startPlayback];
    }
}

- (void)mediaPlayerStateChanged:(NSNotification *)notification
{
    VLCMediaPlayerState currentState = self.mediaPlayer.state;

    switch (currentState)
    {
        case VLCMediaPlayerStateBuffering:
        {
            /* attach delegate */
            self.mediaPlayer.media.delegate = self;

            /* on-the-fly values through hidden API */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            [self.mediaPlayer performSelector:@selector(setTextRendererFont:) withObject:@"Helvetica Neue"];
            [self.mediaPlayer performSelector:@selector(setTextRendererFontSize:) withObject:@"16"];
            [self.mediaPlayer performSelector:@selector(setTextRendererFontColor:) withObject:@"16777215"];
            [self.mediaPlayer performSelector:@selector(setTextRendererFontForceBold:) withObject:@(YES)];
#pragma clang diagnostic pop
            break;
        }
        case VLCMediaPlayerStateError:
        {
            NSLog(@"Playback failed");
            dispatch_async(dispatch_get_main_queue(),^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kVLCPlaybackServicePlaybackDidFail object:self];
            });
            self.sessionWillRestart = NO;
            [self stopPlayback];
            break;
        }
        case VLCMediaPlayerStateEnded:
        {
            [self stopPlayback];
            break;
        }
        case VLCMediaPlayerStateStopped:
        {
            [self stopPlayback];
            break;
        }
        default:
            break;
    }

    if ([self.delegate respondsToSelector:@selector(mediaPlayerStateChanged:isPlaying:currentMediaHasTrackToChooseFrom:currentMediaHasChapters:forPlaybackService:)])
    {
        [self.delegate mediaPlayerStateChanged:currentState
                                     isPlaying:self.mediaPlayer.isPlaying
              currentMediaHasTrackToChooseFrom:self.currentMediaHasTrackToChooseFrom
                       currentMediaHasChapters:self.currentMediaHasChapters
                         forPlaybackService:self];
    }

    // TODO: Implement this?
    //[self setNeedsMetadataUpdate];
}

- (VLCTime *)playedTime
{
    return [self.mediaPlayer time];
}

- (VLCTime *)remainingTime
{
    return [self.mediaPlayer remainingTime];
}

- (void)recoverPlaybackState
{
    if ([self.delegate respondsToSelector:@selector(mediaPlayerStateChanged:isPlaying:currentMediaHasTrackToChooseFrom:currentMediaHasChapters:forPlaybackService:)])
    {
        [self.delegate mediaPlayerStateChanged:_mediaPlayer.state
                                     isPlaying:self.isPlaying
              currentMediaHasTrackToChooseFrom:self.currentMediaHasTrackToChooseFrom
                       currentMediaHasChapters:self.currentMediaHasChapters
                         forPlaybackService:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
    {
        [self.delegate prepareForMediaPlayback:self];
    }
}

- (float)playbackPosition
{
    return self.mediaPlayer.position;
}

#pragma mark - playback controls

- (void)playPause
{
    [self.mediaPlayer isPlaying] ? [self pause] : [self play];
}

- (void)play
{
    [self.listPlayer play];
    [[NSNotificationCenter defaultCenter] postNotificationName:kVLCPlaybackServicePlaybackDidResume object:self];
}

- (void)pause
{
    [self.listPlayer pause];
    [[NSNotificationCenter defaultCenter] postNotificationName:kVLCPlaybackServicePlaybackDidPause object:self];
}

- (void)jumpForward:(NSTimeInterval)interval
{
    if (self.mediaPlayer.isPlaying)
    {
        [self pause];
        [self.mediaPlayer jumpForward:interval];
        [self play];
    }
}

- (void)jumpBackward:(NSTimeInterval)interval
{
    if (self.mediaPlayer.isPlaying)
    {
        [self pause];
        [self.mediaPlayer jumpBackward:interval];
        [self play];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([object isEqual:self.mediaPlayer])
    {
        
        if ([keyPath isEqualToString:@"time"])
        {
            
        }
        
        if ([keyPath isEqualToString:@"remainingTime"])
        {
            
        }
        
        if ([self.delegate respondsToSelector:@selector(playbackPositionUpdated:)])
        {
            [self.delegate playbackPositionUpdated:self];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kVLCPlaybackServicePlaybackPositionUpdated
                                                            object:self];
        
    }
}

#pragma mark - Setters

- (void)setVideoTrackEnabled:(BOOL)enabled
{
    if (!enabled)
    {
        self.mediaPlayer.currentVideoTrackIndex = -1;
    }
    else if (self.mediaPlayer.currentVideoTrackIndex == -1)
    {
        for (NSNumber *trackId in self.mediaPlayer.videoTrackIndexes)
        {
            if (trackId.intValue != -1) {
                self.mediaPlayer.currentVideoTrackIndex = trackId.intValue;
                break;
            }
        }
    }
}

- (void)setVideoOutputView:(UIView *)videoOutputView
{
    if (videoOutputView)
    {
        if (self.actualVideoOutputView.superview != nil)
        {
            [self.actualVideoOutputView removeFromSuperview];
        }

        self.actualVideoOutputView.frame = (CGRect){CGPointZero, videoOutputView.frame.size};

        [self setVideoTrackEnabled:true];

        [videoOutputView addSubview:self.actualVideoOutputView];
        [self.actualVideoOutputView layoutSubviews];
        [self.actualVideoOutputView updateConstraints];
        [self.actualVideoOutputView setNeedsLayout];
    }
    else
    {
        [self.actualVideoOutputView removeFromSuperview];
    }
    

    self.videoOutputViewWrapper = videoOutputView;
}

- (UIView *)videoOutputView
{
    return self.videoOutputViewWrapper;
}

@end
