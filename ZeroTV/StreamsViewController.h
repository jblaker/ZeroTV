//
//  StreamsViewController.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "BaseTableViewController.h"

@class StreamingGroup;

NS_ASSUME_NONNULL_BEGIN

@interface StreamsViewController : BaseTableViewController

@property (nonatomic, strong) StreamingGroup *selectedGroup;
@property (nonatomic, strong) UIImage *backgroundImage;

@end

NS_ASSUME_NONNULL_END
