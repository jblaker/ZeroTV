//
//  SearchResultsController.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/24/20.
//

#import <UIKit/UIKit.h>

@class StreamInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol SearchResultsControllerDelegate <NSObject>

- (void)didSelectStream:(StreamInfo *)streamInfo;

@end

@interface SearchResultsController : UITableViewController<UISearchResultsUpdating>

@property (nonatomic, strong) NSArray *streams;
@property (nonatomic, weak) id<SearchResultsControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
