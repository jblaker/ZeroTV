//
//  UIViewController+Additions.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/26/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Additions)

- (void)showErrorAlert:(NSError *)error completionHandler:(void (^)(void))completionHandler;
- (void)showToastMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
