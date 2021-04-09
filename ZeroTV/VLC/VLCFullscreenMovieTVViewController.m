//
//  VLCFullscreenMovieTVViewController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "VLCFullscreenMovieTVViewController.h"
#import "SubtitlesViewController.h"
#import "UIViewController+Additions.h"
#import "EpisodeManager.h"
#import "ProgressView.h"

#import <GameController/GameController.h>

static NSString * const kSubtitleOptionsSegueId = @"SubtitleSelection";

typedef NS_ENUM(NSUInteger, GamepadEdge)
{
    GamepadEdgeCenter = 0,
    GamepadEdgeLeft,
    GamepadEdgeRight
};

@interface VLCFullscreenMovieTVViewController ()<SubtitlesViewControllerDelegate, UIGestureRecognizerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIView *movieView;
@property (nonatomic, weak) IBOutlet UIView *topContainerView;
@property (nonatomic, weak) IBOutlet ProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *subtitleOffsetLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topContainerTopConstraint;
@property (nonatomic, weak) IBOutlet UIButton *selectSubtitlesButton;

@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *playPauseButtonRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *singleClickRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *menuTapRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *upSwipeGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *downSwipeGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) BOOL presentingSubtitleOptions;
@property (nonatomic, assign) BOOL elementarySubsAvailable;
@property (nonatomic, assign) BOOL topContainerVisible;
@property (nonatomic, strong) NSTimer *subtitleCheckTimer;
@property (nonatomic, strong) NSTimer *bottomContainerTimer;
@property (nonatomic, strong) GCMicroGamepad *gamepad;
@property (nonatomic, assign) GamepadEdge activeGamepadEdge;

@end

@implementation VLCFullscreenMovieTVViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.movieView.backgroundColor = [UIColor blackColor];
    
    self.topContainerView.layer.cornerRadius = 50;
        
    self.subtitleOffsetLabel.text = nil;
    
    self.progressView.alpha = 0.0;
    
    // Hide the top container initially
    self.topContainerTopConstraint.constant = -(CGRectGetHeight(self.topContainerView.frame) + 70);
    
    if (!self.selectedStream.isVOD)
    {
        self.subtitleCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            
            VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
            NSArray *videoSubTitlesNames = vpc.mediaPlayer.videoSubTitlesNames;
            
            if (videoSubTitlesNames.count > 1)
            {
                [self showToastMessage:@"Subtitles now available"];
                self.elementarySubsAvailable = YES;
                
                [self.subtitleCheckTimer invalidate];
            }
            
        }];

    }

    [self setUpGestures];
    
    if (![self setUpGameController])
    {
        NSLog(@"Failed to set up game controller");
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    vpc.videoOutputView = nil;
    vpc.videoOutputView = self.movieView;
    
    self.movieView.userInteractionEnabled = NO;
    
    if (self.presentingSubtitleOptions)
    {
        self.presentingSubtitleOptions = NO;
    }
    else
    {
        VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
        vpc.delegate = self;
        [vpc recoverPlaybackState];
        
        if (self.selectedStream.isVOD)
        {
            NSNumber *episodeProgress = [EpisodeManager progressForEpisode:self.selectedStream];
            if (episodeProgress.intValue > (60 * 1000))
            {
                [self handleEpisodePartiallyWatched:episodeProgress];
            }
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (!self.presentingSubtitleOptions)
    {
        VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
        if (vpc.videoOutputView == self.movieView)
        {
            vpc.videoOutputView = nil;
        }
        
        [EpisodeManager saveProgressForEpisode:self.selectedStream withPlaybackTime:vpc.mediaPlayer.time.intValue];

        [vpc stopPlayback];
        
        if (self.subtitleCheckTimer.isValid)
        {
            [self.subtitleCheckTimer invalidate];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSubtitleOptionsSegueId])
    {
        SubtitlesViewController *vc = segue.destinationViewController;
        vc.selectedStream = self.selectedStream;
        vc.videoSubTitlesNames = [VLCPlaybackService.sharedInstance.mediaPlayer videoSubTitlesNames];
        vc.delegate = self;
        
        self.presentingSubtitleOptions = YES;
    }
}

#pragma mark - Helper Methods

- (void)handleEpisodePartiallyWatched:(NSNumber *)progress
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Resume from where you left off?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        int seconds = progress.intValue;
        vpc.mediaPlayer.time = [VLCTime timeWithInt:seconds];
        [vpc play];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [vpc play];
    }]];
    
    [self presentViewController:alertController animated:YES completion:^{
        [vpc pause];
    }];
}

- (BOOL)setUpGameController
{
    for (GCController *controller in GCController.controllers)
    {
        if (controller.microGamepad)
        {
            self.gamepad = controller.microGamepad;
            break;
        }
    }

    __weak typeof(self) weakSelf = self;
    self.gamepad.reportsAbsoluteDpadValues = YES;
    self.gamepad.dpad.valueChangedHandler = ^void(GCControllerDirectionPad *dpad, float xValue, float yValue)
    {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        CGFloat threshold = 0.5;
        if (xValue > threshold)
        {
            strongSelf.activeGamepadEdge = GamepadEdgeRight;
        }
        else if (xValue < -threshold)
        {
            strongSelf.activeGamepadEdge = GamepadEdgeLeft;
        }
        else
        {
            strongSelf.activeGamepadEdge = GamepadEdgeCenter;
        }
    };

    return self.gamepad != nil;
}

- (void)showHideProgressView:(BOOL)show
{
    [UIView animateWithDuration:0.25 animations:^{
        self.progressView.alpha = show ? 1.0 : 0.0;
    }];
}

- (void)showThenHideBottomContainer
{
    if (self.bottomContainerTimer.isValid)
    {
        [self.bottomContainerTimer invalidate];
    }
    
    [self showHideProgressView:YES];
    
    self.bottomContainerTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [self showHideProgressView:NO];
    }];
}

#pragma mark - IBActions

- (IBAction)subtitlesButtonPressed:(UIButton *)sender
{
    if (!self.topContainerVisible)
    {
        return;
    }
    
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    [vpc pause];

    [self performSegueWithIdentifier:kSubtitleOptionsSegueId sender:nil];
}

- (IBAction)subtitleOffsetButtonPressed:(UIButton *)sender
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    
    NSInteger oneMil = 1000000;
    
    switch(sender.tag)
    {
        case 1:
            vpc.mediaPlayer.currentVideoSubTitleDelay -= (oneMil/2);
            break;
        case 2:
            vpc.mediaPlayer.currentVideoSubTitleDelay += (oneMil/2);
            break;
        case 3:
            vpc.mediaPlayer.currentVideoSubTitleDelay = 0;
            break;
    }
    
    self.subtitleOffsetLabel.text = [NSString stringWithFormat:@"Current Offset: %.2fs", (float)vpc.mediaPlayer.currentVideoSubTitleDelay/oneMil];
}

#pragma mark - Gestures

- (void)setUpGestures
{
    self.playPauseButtonRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseHandler:)];
    self.playPauseButtonRecognizer.numberOfTapsRequired = 1;
    self.playPauseButtonRecognizer.allowedPressTypes = @[ @(UIPressTypePlayPause) ];
    [self.view addGestureRecognizer:self.playPauseButtonRecognizer];
    
    self.singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapHandler:)];
    self.singleTapRecognizer.numberOfTapsRequired = 1;
    self.singleTapRecognizer.allowedPressTypes = @[ ];
    self.singleTapRecognizer.allowedTouchTypes = @[ @(UITouchTypeIndirect) ];
    [self.view addGestureRecognizer:self.singleTapRecognizer];
    
    self.upSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureRecognized:)];
    self.upSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    self.upSwipeGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.upSwipeGestureRecognizer];
    
    self.downSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureRecognized:)];
    self.downSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:self.downSwipeGestureRecognizer];
    
    self.singleClickRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleClickHandler:)];
    self.singleClickRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.singleClickRecognizer];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    self.panGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    
    self.menuTapRecognizer  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuTapGesture:)];
    self.menuTapRecognizer.allowedPressTypes = @[@(UIPressTypeMenu)];
    self.menuTapRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.menuTapRecognizer];
}

- (void)playPauseHandler:(UITapGestureRecognizer *)tapGestureRecognizer
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];

    [vpc playPause];
    
    [self showHideProgressView:vpc.mediaPlayer.isPlaying];
}

- (void)swipeGestureRecognized:(UISwipeGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateRecognized:
        {
            if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionDown && !self.topContainerVisible)
            {
                self.selectSubtitlesButton.userInteractionEnabled = YES;
                [UIView animateWithDuration:0.25 animations:^{
                    self.topContainerTopConstraint.constant = 0;
                    [self.view layoutIfNeeded];
                } completion:^(BOOL finished) {
                    self.topContainerVisible = YES;
                }];
            }
            
            if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionUp && self.topContainerVisible)
            {
                self.selectSubtitlesButton.userInteractionEnabled = NO;
                [UIView animateWithDuration:0.25 animations:^{
                    self.topContainerTopConstraint.constant = -(CGRectGetHeight(self.topContainerView.frame) + 70);
                    [self.view layoutIfNeeded];
                } completion:^(BOOL finished) {
                    self.topContainerVisible = NO;
                }];
            }
            break;
        }
        default:
            break;
    }
}

- (void)singleClickHandler:(UITapGestureRecognizer *)singleClicker
{
    if (singleClicker.state == UIGestureRecognizerStateRecognized)
    {
        VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];

        if (self.progressView.scrubbing)
        {
            // Confirm scrubbing
            [self stopScrubbing];
            [vpc.mediaPlayer setPosition:self.progressView.scrubbingFraction];
            [vpc play];
        }
        else
        {
        
            switch(self.activeGamepadEdge)
            {
                case GamepadEdgeRight:
                    [vpc jumpForward:10];
                    [self showThenHideBottomContainer];
                    break;
                case GamepadEdgeLeft:
                    [vpc jumpBackward:10];
                    [self showThenHideBottomContainer];
                    break;
                default:
                    [self playPauseHandler:nil];
                    break;
            }
            
        }
    }
}

- (void)singleTapHandler:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self showThenHideBottomContainer];
}

- (void)handleMenuTapGesture:(UITapGestureRecognizer *)gestureRecognizer
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    
    [self stopScrubbing];
    [vpc play];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];

    if (!vpc.mediaPlayer.isSeekable)
    {
        return;
    }

    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            return;
        default:
            break;
    }
    
    ProgressView *progressView = self.progressView;
    
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    
    if (!progressView.scrubbing)
    {
        if (ABS(translation.x) > 150.0)
        {
            [self startScrubbing];
        }
        else
        {
            return;
        }
    }
    
    const CGFloat scaleFactor = 8.0;
    CGFloat fractionInView = translation.x / CGRectGetWidth(self.view.bounds) / scaleFactor;
    CGFloat scrubbingFraction = MAX(0.0, MIN(progressView.scrubbingFraction + fractionInView, 1.0));

    if (ABS(scrubbingFraction - progressView.playbackFraction) < 0.005)
    {
        scrubbingFraction = progressView.playbackFraction;
    }
    else
    {
        translation.x = 0.0;
        [gestureRecognizer setTranslation:translation inView:self.view];
    }
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        progressView.scrubbingFraction = scrubbingFraction;
    } completion:nil];
    [self updateTimeLabelsForScrubbingFraction:scrubbingFraction];
}

- (void)startScrubbing
{
    // Add menu and select gestures to confirm or cancel scrubbing
    self.progressView.scrubbing = YES;
}

- (void)stopScrubbing
{
    self.progressView.scrubbing = NO;
    
    [self showHideProgressView:NO];
}

- (void)updateTimeLabelsForScrubbingFraction:(CGFloat)scrubbingFraction
{
    ProgressView *progressView = self.progressView;
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    
    // MAX 1, _ is ugly hack to prevent --:-- instead of 00:00
    int scrubbingTimeInt = MAX(1, vpc.mediaDuration * scrubbingFraction);
    
    VLCTime *scrubbingTime = [VLCTime timeWithInt:scrubbingTimeInt];
    [progressView updatesScrubbingTime:[scrubbingTime stringValue]];
    
    VLCTime *remainingTime = [VLCTime timeWithInt:-(int)(vpc.mediaDuration - scrubbingTime.intValue)];
    [progressView updateRemainingTime:[remainingTime stringValue]];
}

#pragma mark - Playback Monitoring

- (void)playbackPositionUpdated:(VLCPlaybackService *)playbackService
{
    VLCPlaybackService *controller = VLCPlaybackService.sharedInstance;
    
    NSString *remainingTime = controller.remainingTime.stringValue;
    NSString *playedTime = controller.playedTime.stringValue;
    
    self.progressView.playbackFraction = playbackService.playbackPosition;
    [self.progressView updateRemainingTime:remainingTime];
    [self.progressView updatePlayedTime:playedTime];
    
    //NSLog(@"Played Time: %@ | Remaining Time: %@", playedTime, remainingTime);
}

- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
             forPlaybackService:(VLCPlaybackService *)playbackService
{
    NSString *state;
    switch (currentState)
    {
        case VLCMediaPlayerStateStopped:
            state = @"VLCMediaPlayerStateStopped";
            break;
        case VLCMediaPlayerStateOpening:
            state = @"VLCMediaPlayerStateOpening";
            break;
        case VLCMediaPlayerStateBuffering:
            state = @"VLCMediaPlayerStateBuffering";
            break;
        case VLCMediaPlayerStateEnded:
            state = @"VLCMediaPlayerStateEnded";
            break;
        case VLCMediaPlayerStateError:
            state = @"VLCMediaPlayerStateError";
            break;
        case VLCMediaPlayerStatePlaying:
            state = @"VLCMediaPlayerStatePlaying";
            break;
        case VLCMediaPlayerStatePaused:
            state = @"VLCMediaPlayerStatePaused";
            break;
        case VLCMediaPlayerStateESAdded:
        {
            state = @"VLCMediaPlayerStateESAdded";
            break;
        }
    }
        
    //NSLog(@"State changed: %@ | Playing: %@ | Tracks: %@ | Chapters: %@", state, isPlaying ? @"YES" : @"NO", currentMediaHasTrackToChooseFrom ? @"YES" : @"NO", currentMediaHasChapters ? @"YES" : @"NO");
}

#pragma mark - SubtitlesViewControllerDelegate

- (void)didConfigureSubtitles:(BOOL)didConfigure
{
    self.selectedStream.didDownloadSubFile = didConfigure;
    
    __weak typeof(self) weakSelf = self;

    [self dismissViewControllerAnimated:YES completion:^{
        if (didConfigure)
        {
            [VLCPlaybackService.sharedInstance applyCachedSubtitle];
        }
        else
        {
            [VLCPlaybackService.sharedInstance clearSubtitle];
        }
        
        [weakSelf playPauseHandler:nil];
    }];
}

- (void)didEncounterError:(NSError *)error
{
    self.selectedStream.didDownloadSubFile = NO;

    __weak typeof(self) weakSelf = self;
    
    [self showErrorAlert:error completionHandler:^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf dismissViewControllerAnimated:YES completion:^{

            [VLCPlaybackService.sharedInstance clearSubtitle];
            
            [strongSelf playPauseHandler:nil];
            
        }];

    }];
}

- (void)selectedElementarySubtitleAtIndex:(NSInteger)index
{
    VLCPlaybackService *playbackService = VLCPlaybackService.sharedInstance;
    
    __weak typeof(self) weakSelf = self;
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        if (index >= 0 && index < playbackService.mediaPlayer.videoSubTitlesIndexes.count)
        {
            NSLog(@"Selected elementary subtitle at index %li", (long)index);
            playbackService.mediaPlayer.currentVideoSubTitleIndex = [playbackService.mediaPlayer.videoSubTitlesIndexes[index] intValue];
        }
        
        [weakSelf playPauseHandler:nil];
    }];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];

    if (gestureRecognizer == self.upSwipeGestureRecognizer)
    {
        return self.selectSubtitlesButton.isFocused;
    }
    
    if (gestureRecognizer == self.panGestureRecognizer)
    {
        return !vpc.mediaPlayer.isPlaying;
    }
    
    if (gestureRecognizer == self.menuTapRecognizer)
    {
        return self.progressView.scrubbing;
    }
    
    return YES;
}

@end
