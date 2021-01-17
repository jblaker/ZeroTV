//
//  SubtitlesViewController.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "BaseTableViewController.h"
#import "StreamInfo.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SubtitlesViewControllerDelegate <NSObject>

- (void)didConfigureSubtitles:(BOOL)didConfigure;
- (void)didEncounterError:(NSError *)error;
- (void)selectedElementarySubtitleAtIndex:(NSInteger)index;

@end

@interface SubtitlesViewController : BaseTableViewController

@property (nonatomic, strong) StreamInfo *selectedStream;
@property (nonatomic, strong) NSArray *videoSubTitlesNames;
@property (nonatomic, assign) id<SubtitlesViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
