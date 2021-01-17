//
//  GroupsViewController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "GroupsViewController.h"
#import "StreamingGroup.h"
#import "StreamInfo.h"
#import "StreamsViewController.h"
#import "M3U8Manager.h"
#import "CacheManager.h"
#import "FavoritesViewController.h"
#import "UIViewController+Additions.h"

static NSString * const kTableCellId = @"TableViewCell";
static NSString * const kStreamsSegue = @"ShowStreams";
static NSString * const kFavoritesSegue = @"ShowFavorites";

@interface GroupsViewController ()

@property (nonatomic, weak) IBOutlet UIButton *refreshButton;
@property (nonatomic, weak) IBOutlet UILabel *cachedDateLabel;

@property (nonatomic, strong) NSDictionary *groups;
@property (nonatomic, strong) StreamingGroup *selectedGroup;

@end

@implementation GroupsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Categories";
    
    self.cachedDateLabel.text = nil;
    
    BOOL useLocalFile = NO;
    
    if (useLocalFile)
    {
        [self useLocalFile];
    }
    else
    {
        [self fetchManifest:YES];
    }
    
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kTableCellId];
}

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return @[self.tableView, self.refreshButton];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kStreamsSegue])
    {
        StreamsViewController *vc = segue.destinationViewController;
        vc.selectedGroup = self.selectedGroup;
    }
    
    if ([segue.identifier isEqualToString:kFavoritesSegue])
    {
        FavoritesViewController *vc = segue.destinationViewController;
        vc.vodGroup = self.groups[@"TV VOD"];
    }
}

- (void)fetchManifest:(BOOL)useCached
{
    if (useCached)
    {
        NSData *cachedData = [CacheManager cachedDataNamed:kCachedManifestFilename];
        
        if (cachedData)
        {
            NSDate *cacheDate = [NSUserDefaults.standardUserDefaults objectForKey:@"cacheDate"];
            if (cacheDate)
            {
                [self updateLastUpdatedLabel:cacheDate];
            }
            
            self.groups = [M3U8Manager parseManifest:cachedData];
            [self.tableView reloadData];
            NSLog(@"Using cached data");
            return;
        }
    }
    
    [self showSpinner:YES];

    __weak typeof(self) weakSelf = self;
    
    [M3U8Manager fetchManifest:^(NSData * _Nullable data, NSError * _Nullable error) {
        
        __strong typeof(weakSelf) strongSelf = self;
        
        [strongSelf showSpinner:NO];
       
        if (error)
        {
            [strongSelf showErrorAlert:error completionHandler:^{
                
            }];
        }
        else
        {
            NSError *error = [CacheManager cacheData:data filename:kCachedManifestFilename];
            if (error)
            {
                [strongSelf showErrorAlert:error completionHandler:^{
                    strongSelf.groups = [M3U8Manager parseManifest:data];
                    [strongSelf.tableView reloadData];
                }];
            }
            else
            {
                NSDate *currentDate = NSDate.date;
                [NSUserDefaults.standardUserDefaults setObject:currentDate forKey:@"cacheDate"];
                [NSUserDefaults.standardUserDefaults synchronize];
                
                [strongSelf updateLastUpdatedLabel:currentDate];
                
                strongSelf.groups = [M3U8Manager parseManifest:data];
                [strongSelf.tableView reloadData];
            }
        }
        
    }];
}

- (void)updateLastUpdatedLabel:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = kCFDateFormatterShortStyle;
    NSString *dateString = [formatter stringFromDate:date];
    self.cachedDateLabel.text = [NSString stringWithFormat:@"Last updated %@", dateString];
}

- (void)useLocalFile
{
    NSError *error;
    NSString *localPath = [NSBundle.mainBundle pathForResource:@"iptv" ofType:@"m3u8"];
    NSData *localData = [NSData dataWithContentsOfFile:localPath options:0 error:&error];

    if (error)
    {
        [self showErrorAlert:error completionHandler:^{
            
        }];
    }
    else
    {
        self.groups = [M3U8Manager parseManifest:localData];
        [self.tableView reloadData];
    }
}

#pragma mark - IBActions

- (IBAction)refreshButtonPressed:(id)sender
{
    [self fetchManifest:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 1;
    }
    return self.groups.allKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableCellId];
    
    if (indexPath.section == 0)
    {
        cell.textLabel.text = @"Favorite Shows";
    }
    else
    {
        StreamingGroup *group = self.groups.allValues[indexPath.row];
        cell.textLabel.text = group.name;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0)
    {
        [self performSegueWithIdentifier:kFavoritesSegue sender:nil];
    }
    else
    {
        self.selectedGroup = self.groups.allValues[indexPath.row];
        [self performSegueWithIdentifier:kStreamsSegue sender:nil];
    }
}

@end
