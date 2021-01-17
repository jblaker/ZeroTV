//
//  FavoritesViewController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/24/20.
//

#import "FavoritesViewController.h"
#import "StreamingGroup.h"
#import "StreamInfo.h"
#import "StreamsViewController.h"

static NSString * const kStreamsSegue = @"ShowStreams";
static NSString * const kTableCellId = @"TableViewCell";

@interface FavoritesViewController ()

@property (nonatomic, strong) NSArray *favorites;
@property (nonatomic, strong) StreamingGroup *selectedGroup;

@end

@implementation FavoritesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Favorites";
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    self.favorites = dict[@"FavoriteShows"];
    
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kTableCellId];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kStreamsSegue])
    {
        StreamsViewController *vc = segue.destinationViewController;
        vc.selectedGroup = self.selectedGroup;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *favName = self.favorites[indexPath.row];
    StreamingGroup *favoriteGroup = [[StreamingGroup alloc] initWithName:favName];
        
    NSMutableArray *addedTitles = @[].mutableCopy;
    
    for (StreamInfo *streamInfo in self.vodGroup.streams)
    {
        if ([streamInfo.name containsString:favName] && [addedTitles indexOfObject:streamInfo.name] == NSNotFound)
        {
            [favoriteGroup.streams addObject:streamInfo];
            [addedTitles addObject:streamInfo.name];
        }
    }

    NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)];
    [favoriteGroup.streams sortUsingDescriptors:@[nameSortDescriptor]];
    
    self.selectedGroup = favoriteGroup;
    
    [self performSegueWithIdentifier:kStreamsSegue sender:nil];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableCellId];
    
    cell.textLabel.text = self.favorites[indexPath.row];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.favorites.count;
}

@end
