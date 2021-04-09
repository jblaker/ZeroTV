//
//  ProgressView.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 4/8/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProgressView : UIView

@property (nonatomic, assign) CGFloat playbackFraction;
@property (nonatomic, assign) CGFloat scrubbingFraction;
@property (nonatomic, assign) BOOL scrubbing;

- (void)updatePlayedTime:(NSString *)playedTime;
- (void)updateRemainingTime:(NSString *)remainingTime;
- (void)updatesScrubbingTime:(NSString *)scrubbingTime;

@end

NS_ASSUME_NONNULL_END
