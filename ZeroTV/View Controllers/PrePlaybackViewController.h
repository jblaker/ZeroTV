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

@property (nonatomic, strong) NSObject<GenericStream> *selectedStream;

- (void)checkForCaptions;
- (void)setUpPlayer:(NSObject<GenericStream> *)selectedStream;
- (NSObject<GenericStream> *)streamAtIndexPath:(NSIndexPath *)indexPath;
- (void)showMarkAsOptions:(NSObject<GenericStream> *)selectedStream;

@end

NS_ASSUME_NONNULL_END
