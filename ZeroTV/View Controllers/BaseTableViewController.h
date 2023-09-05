//
//  BaseTableViewController.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import <UIKit/UIKit.h>

@class StreamInfo;

extern NSString * const _Nonnull kTableCellId;

NS_ASSUME_NONNULL_BEGIN

@interface BaseTableViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (void)showSpinner:(BOOL)show;

- (void)buildBackgroundView;

@end

NS_ASSUME_NONNULL_END
