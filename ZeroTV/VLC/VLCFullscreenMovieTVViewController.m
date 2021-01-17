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

static NSString * const kSubtitleOptionsSegueId = @"SubtitleSelection";

@interface VLCFullscreenMovieTVViewController ()<SubtitlesViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIView *movieView;
@property (nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *playedTimeLabel;
@property (nonatomic, weak) IBOutlet UIView *progressContainer;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *jumpButtons;

@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *playPauseButtonRecognizer;
@property (nonatomic, assign) BOOL presentingSubtitleOptions;
@property (nonatomic, assign) BOOL elementarySubsAvailable;
@property (nonatomic, strong) NSTimer *subtitleCheckTimer;

@end

@implementation VLCFullscreenMovieTVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.movieView.backgroundColor = [UIColor blackColor];
    self.progressContainer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.progressContainer.alpha = 0.0;
    
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
        
        for(UIButton *jumpButton in self.jumpButtons)
        {
            jumpButton.hidden = YES;
        }
    }
    
    [self setUpGestures];
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
            if (episodeProgress.intValue > 60)
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

- (void)toggleProgressContainerVisibility
{
    if (self.progressContainer.alpha == 1.0)
    {
        [UIView animateWithDuration:0.25 animations:^{
            self.progressContainer.alpha = 0.0;
        }];
    }
    else
    {
        [UIView animateWithDuration:0.25 animations:^{
            self.progressContainer.alpha = 1.0;
        }];
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

#pragma mark - IBActions

- (void)singleTapHandler:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self toggleProgressContainerVisibility];
}

- (IBAction)subtitlesButtonPressed:(id)sender
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    [vpc pause];

    [self performSegueWithIdentifier:kSubtitleOptionsSegueId sender:nil];
}

- (void)playPauseHandler:(UITapGestureRecognizer *)tapGestureRecognizer
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];

    [vpc playPause];
    
    [self toggleProgressContainerVisibility];
}

- (IBAction)jumpButtonPressed:(UIButton *)button
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];

    switch(button.tag)
    {
        case 0:
            [vpc jumpBackward:15];
            break;
        case 1:
            [vpc jumpBackward:30];
            break;
        case 2:
            [vpc jumpForward:15];
            break;
        case 3:
            [vpc jumpForward:30];
            break;
    }
}

- (IBAction)subtitleOffsetButtonPressed:(UIButton *)button
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    
    NSInteger oneMil = 1000000;
    
    switch(button.tag)
    {
        case 0:
            vpc.mediaPlayer.currentVideoSubTitleDelay -= (oneMil/2);
            break;
        case 1:
            vpc.mediaPlayer.currentVideoSubTitleDelay -= oneMil;
            break;
        case 2:
            vpc.mediaPlayer.currentVideoSubTitleDelay += (oneMil/2);
            break;
        case 3:
            vpc.mediaPlayer.currentVideoSubTitleDelay += oneMil;
            break;
    }
    
    NSLog(@"Subtitle offset is now %li", (long)vpc.mediaPlayer.currentVideoSubTitleDelay);
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
}

#pragma mark -

- (void)playbackPositionUpdated:(VLCPlaybackService *)playbackService
{
    VLCPlaybackService *controller = VLCPlaybackService.sharedInstance;
    
    NSString *remainingTime = controller.remainingTime.stringValue;
    NSString *playedTime = controller.playedTime.stringValue;
    
    self.progressView.progress = playbackService.playbackPosition;
    self.remainingTimeLabel.text = remainingTime;
    self.playedTimeLabel.text = playedTime;
    
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

@end
