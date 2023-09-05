//
//  FavoritesViewController.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/24/20.
//

#import "BaseTableViewController.h"

@class StreamingGroup;

NS_ASSUME_NONNULL_BEGIN

@interface FavoritesViewController : BaseTableViewController

@property (nonatomic, strong) StreamingGroup *vodGroup;
@property (nonatomic, strong, nullable) NSString *deepLinkShowName;

@end

NS_ASSUME_NONNULL_END
