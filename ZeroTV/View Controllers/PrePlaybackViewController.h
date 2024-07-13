//
//  PrePlaybackViewController.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 3/23/22.
//

#import "BaseTableViewController.h"

@class StreamInfo, Bookmark;

@protocol GenericStream;

NS_ASSUME_NONNULL_BEGIN

@interface PrePlaybackViewController : BaseTableViewController

@property (nonatomic, strong) id<GenericStream> selectedStream;

- (void)checkForCaptions;
- (void)setUpPlayer:(id<GenericStream> _Nonnull)selectedStream;
- (id<GenericStream> _Nullable)streamAtIndexPath:(NSIndexPath * _Nonnull)indexPath;
- (void)showMarkAsOptions:(id<GenericStream> _Nonnull)selectedStream;

@end

NS_ASSUME_NONNULL_END
