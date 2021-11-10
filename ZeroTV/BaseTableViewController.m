//
//  BaseTableViewController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "BaseTableViewController.h"
#import "StreamInfo.h"

#import "VLCPlaybackService.h"

@import TVVLCKit;

@interface BaseTableViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation BaseTableViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self buildBackgroundView];
}

- (void)buildBackgroundView
{
    UIImage *image = [UIImage imageNamed:@"Background"];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];
}

- (void)showSpinner:(BOOL)show
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (show)
        {
            self.tableView.userInteractionEnabled = NO;
            [UIView animateWithDuration:0.25 animations:^{
                self.tableView.alpha = 0.2;
            }];
            
            [self.spinner startAnimating];
            
            self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
            [self.view addSubview:self.spinner];
            [NSLayoutConstraint activateConstraints:@[
                [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                [self.spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
            ]];
        }
        else
        {
            [self.spinner removeFromSuperview];
            self.tableView.userInteractionEnabled = YES;
            self.tableView.alpha = 1.0;
        }
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [UITableViewCell new];
}

@end
