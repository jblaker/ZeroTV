//
//  PrePlaybackViewController.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 3/23/22.
//

#import "BaseTableViewController.h"

@class StreamInfo;

NS_ASSUME_NONNULL_BEGIN

@interface PrePlaybackViewController : BaseTableViewController

@property (nonatomic, strong) StreamInfo *selectedStream;

- (void)checkForCaptions;
- (void)setUpPlayer:(StreamInfo *)selectedStream;
- (StreamInfo *)streamAtIndexPath:(NSIndexPath *)indexPath;
- (void)showMarkAsOptions:(StreamInfo *)selectedStream;

@end

NS_ASSUME_NONNULL_END
