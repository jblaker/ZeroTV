//
//  ProgressView.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 4/8/21.
//

#import "ProgressView.h"

static CGFloat const kPlayedTimeLabelVerticalMargin = 16.0;
//static CGFloat const kPlayedTimeLabelHorizontalMargin = 10.0;
static CGFloat const kScrubLineHeight = 40.0;
static CGFloat const kProgressBarHeight = 15.0;
static CGFloat const kMarkerLineWidth = 2.0;

@interface ProgressView ()

@property (nonatomic, strong) UIView *progressBar;
@property (nonatomic, strong) UIView *progressIndicatorView;
@property (nonatomic, strong) UIView *playedTimeLabelContainer;
@property (nonatomic, strong) UILabel *remainingTimeLabel;
@property (nonatomic, strong) UILabel *playedTimeLabel;
@property (nonatomic, strong) UILabel *scrubTimeLabel;
@property (nonatomic, strong) UIView *scrubLine;
@property (nonatomic, strong) UIView *scrubContainer;

@end

@implementation ProgressView

+ (UIColor *)zeroPinkColor
{
    return [UIColor colorWithRed:179.0/255.0 green:50.0/255.0 blue:58.0/255.0 alpha:1.0];
}

+ (UIFont *)labelFont
{
    return [UIFont boldSystemFontOfSize:24];
}

+ (UILabel *)timeLabel
{
    UILabel *label = [UILabel new];
    label.text = @"00:00";
    label.font = [ProgressView labelFont];
    label.shadowColor = UIColor.blackColor;
    label.shadowOffset = CGSizeMake(2, 2);
    [label sizeToFit];
    return label;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        [self build];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self build];
    }
    return self;
}

#pragma mark - Set Up

- (void)build
{
    [self buildProgressBar];
    [self buildProgressIndicator];
    [self buildPlayedTimeLabel];
    [self buildRemainingTimeLabel];
    [self buildScrubContainer];

    self.scrubContainer.hidden = YES;
}

- (void)buildProgressBar
{
    self.progressBar = [UIView new];
    self.progressBar.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), kProgressBarHeight);
    self.progressBar.backgroundColor =  [UIColor colorWithRed:90.0/255.0 green:90.0/255.0 blue:90.0/255.0 alpha:0.75];
    
    self.progressBar.clipsToBounds = YES;
    self.progressBar.layer.cornerRadius = kProgressBarHeight / 2;
    
    [self addSubview:self.progressBar];
}

- (void)buildProgressIndicator
{
    self.progressIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kMarkerLineWidth, CGRectGetWidth(self.progressBar.frame))];
    [self.progressBar addSubview:self.progressIndicatorView];
    self.progressIndicatorView.backgroundColor = UIColor.whiteColor;
}

- (void)buildPlayedTimeLabel
{
    self.playedTimeLabelContainer = [UIView new];
    self.playedTimeLabelContainer.layer.cornerRadius = 7;
    //self.playedTimeLabelContainer.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.75];
    
    [self addSubview:self.playedTimeLabelContainer];
    
    self.playedTimeLabel = [ProgressView timeLabel];
    //self.playedTimeLabel.textColor = [ProgressView zeroPinkColor];
    
    [self.playedTimeLabelContainer addSubview:self.playedTimeLabel];
    
    CGRect playedTimeLabelContainerFrame = self.playedTimeLabel.frame;
    //playedTimeLabelContainerFrame.size.width += kPlayedTimeLabelVerticalMargin;
    //playedTimeLabelContainerFrame.size.height += kPlayedTimeLabelHorizontalMargin;
    playedTimeLabelContainerFrame.origin = CGPointMake(0, CGRectGetMaxY(self.progressBar.frame) + 5);
    
    self.playedTimeLabelContainer.frame = playedTimeLabelContainerFrame;
    
    [self updatePlayedTime:self.playedTimeLabel.text];
}

- (void)buildRemainingTimeLabel
{
    self.remainingTimeLabel = [ProgressView timeLabel];
    
    [self addSubview:self.remainingTimeLabel];
    
    [self updateRemainingTime:self.remainingTimeLabel.text];
}

- (void)buildScrubContainer
{
    self.scrubContainer = [UIView new];
    
    self.scrubTimeLabel = [ProgressView timeLabel];
    [self.scrubContainer addSubview:self.scrubTimeLabel];
    
    CGFloat scrubLabelWidth = CGRectGetWidth(self.scrubTimeLabel.frame);
    CGFloat scrubContainerHeight = kScrubLineHeight + CGRectGetHeight(self.scrubTimeLabel.frame);
    CGRect scrubContainerFrame = CGRectMake(0, -scrubContainerHeight+kProgressBarHeight, scrubLabelWidth, scrubContainerHeight);
    self.scrubContainer.frame = scrubContainerFrame;
    
    self.scrubLine = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.scrubTimeLabel.frame), kMarkerLineWidth, kScrubLineHeight)];
    self.scrubLine.backgroundColor = UIColor.whiteColor;
    [self.scrubContainer addSubview:self.scrubLine];
    
    [self addSubview:self.scrubContainer];
}

#pragma mark - Updates

- (void)updateRemainingTime:(NSString *)remainingTime
{
    self.remainingTimeLabel.text = remainingTime;
    [self.remainingTimeLabel sizeToFit];
    
    CGRect frame = self.remainingTimeLabel.frame;
    frame.origin.x = CGRectGetWidth(self.frame) - CGRectGetWidth(self.remainingTimeLabel.frame);
    frame.origin.y = CGRectGetMinY(self.playedTimeLabelContainer.frame) + (kPlayedTimeLabelVerticalMargin / 3);
    self.remainingTimeLabel.frame = frame;
}

- (void)updatePlayedTime:(NSString *)playedTime
{
    self.playedTimeLabel.text = playedTime;
    [self.playedTimeLabel sizeToFit];
    self.playedTimeLabel.center = CGPointMake(CGRectGetWidth(self.playedTimeLabelContainer.frame) / 2, CGRectGetHeight(self.playedTimeLabelContainer.frame) / 2);
}

- (void)updatesScrubbingTime:(NSString *)scrubbingTime
{
    self.scrubTimeLabel.text = scrubbingTime;
    [self.scrubTimeLabel sizeToFit];
}

#pragma mark - Setters

- (void)setLiveStream:(BOOL)liveStream
{
    _liveStream = liveStream;

    if (liveStream)
    {
        self.remainingTimeLabel.hidden = YES;
        self.progressIndicatorView.frame = self.progressBar.frame;
    }
}

- (void)setScrubbing:(BOOL)scrubbing
{
    _scrubbing = scrubbing;
    
    self.scrubContainer.hidden = !scrubbing;
}

- (void)setPlaybackFraction:(CGFloat)playbackFraction
{
    _playbackFraction = MAX(0.0, MIN(playbackFraction, 1.0));
    
    self.scrubbingFraction = _playbackFraction;

    CGRect frame = self.progressIndicatorView.frame;
    frame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(self.progressIndicatorView.frame)) * _playbackFraction;
    
    CGFloat playedTimeWidth = CGRectGetWidth(self.playedTimeLabelContainer.frame);
    CGRect playedTimeContanierFrame = self.playedTimeLabelContainer.frame;
    CGFloat playedTimeLabelContainerX = 0;
    
    if (frame.origin.x >= (playedTimeWidth / 2))
    {
        playedTimeLabelContainerX = frame.origin.x - (playedTimeWidth / 2);
        // Don't let it go past the progress bar
        if ((playedTimeLabelContainerX + playedTimeWidth) >= CGRectGetWidth(self.progressBar.frame))
        {
            playedTimeLabelContainerX = CGRectGetWidth(self.progressBar.frame) - CGRectGetWidth(playedTimeContanierFrame);
        }
    }
    
    playedTimeContanierFrame.origin.x = playedTimeLabelContainerX;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.progressIndicatorView.frame = frame;
        self.playedTimeLabelContainer.frame = playedTimeContanierFrame;
    }];
    
    // Hide the remaining time label when needed
    CGFloat remainingTimeX = CGRectGetMinX(self.remainingTimeLabel.frame);
    CGFloat playedTimeX = CGRectGetMaxX(playedTimeContanierFrame);
    if ((playedTimeX + 20) >= remainingTimeX)
    {
        self.remainingTimeLabel.hidden = YES;
    }
    else
    {
        if (!self.isLiveStream)
        {
            self.remainingTimeLabel.hidden = NO;
        }
    }
}

- (void)setScrubbingFraction:(CGFloat)scrubbingFraction
{
    _scrubbingFraction = MAX(0.0, MIN(scrubbingFraction, 1.0));

    // Position scrub container
    CGFloat scrubContainerMidway = CGRectGetWidth(self.scrubContainer.frame) / 2;
    CGRect scrubLineFrame = self.scrubLine.frame;
    CGRect scrubContainerFrame = self.scrubContainer.frame;
    
    // We want to move the line until it hits the center of the container
    // then we move the whole container until we reach the far right
    scrubLineFrame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(self.scrubLine.frame)) * _scrubbingFraction;
    
    if (scrubLineFrame.origin.x >= (scrubContainerMidway + kMarkerLineWidth))
    {
        scrubContainerFrame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(scrubContainerFrame)) * _scrubbingFraction;

        if (CGRectGetMinX(scrubContainerFrame) + CGRectGetWidth(scrubContainerFrame) == CGRectGetMaxX(self.progressBar.frame))
        {
            // Phase 3
            // Move the scrub line once we get all the way right
            if (scrubLineFrame.origin.x >= CGRectGetWidth(scrubContainerFrame))
            {
                scrubLineFrame.origin.x = CGRectGetWidth(scrubContainerFrame);
            }
            [UIView animateWithDuration:0.25 animations:^{
                self.scrubLine.frame = scrubLineFrame;
            }];
        }
        else
        {
            // Phase 2
            // Move the scrub container
            scrubLineFrame.origin.x = scrubContainerMidway - kMarkerLineWidth;
            self.scrubLine.frame = scrubLineFrame;
            
            [UIView animateWithDuration:0.25 animations:^{
                self.scrubContainer.frame = scrubContainerFrame;
            }];
        }
    }
    else
    {
        // Phase 1
        // Move the scrub line
        scrubContainerFrame.origin.x = 0;
        self.scrubContainer.frame = scrubContainerFrame;
        
        [UIView animateWithDuration:0.25 animations:^{
            self.scrubLine.frame = scrubLineFrame;
        }];
    }
}

@end
