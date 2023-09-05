//
//  UIViewController+Additions.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/26/20.
//

#import "UIViewController+Additions.h"

@implementation UIViewController (Additions)

- (void)showErrorAlert:(NSError *)error completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"An Error Occured" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showToastMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CGRect frame = self.view.frame;
        frame.size.height = 75;
        
        UIView *container = [[UIView alloc] initWithFrame:frame];
        container.alpha = 0.0;
        container.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
        
        UILabel *label = [UILabel new];
        label.text = message;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:30];
        label.frame = frame;
        label.textAlignment = NSTextAlignmentCenter;
        
        [container addSubview:label];
        
        [self.view addSubview:container];
        
        [UIView animateWithDuration:0.25 animations:^{
           
            container.alpha = 1.0;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [UIView animateWithDuration:0.25 animations:^{
                   
                    container.alpha = 0.0;
                    
                }];
                
            });
            
        }];
        
    });
}

@end
