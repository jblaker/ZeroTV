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
static NSString * const kStreamsNASegue = @"ShowStreamsNA";

@interface FavoritesViewController ()

@property (nonatomic, strong) NSArray *favorites;
@property (nonatomic, strong) StreamingGroup *selectedGroup;
@property (nonatomic, strong) NSMutableDictionary *posterImageDictionary;

@end

@implementation FavoritesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Favorites";
    
    self.posterImageDictionary = @{}.mutableCopy;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    NSArray *favoriteShows = dict[@"FavoriteShows"];
    NSMutableArray *activeFavoriteShows = @[].mutableCopy;
    
    for (NSDictionary *show in favoriteShows)
    {
        if ([show[@"active"] boolValue])
        {
            [self loadPosterImageForShow:show];
            [activeFavoriteShows addObject:show];
        }
    }
    
    self.favorites = activeFavoriteShows;
    
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kTableCellId];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.deepLinkShowName)
    {
        int counter = 0;
        for (NSDictionary *show in self.favorites)
        {
            NSString *name = show[@"name"];
            if ([name isEqualToString:self.deepLinkShowName])
            {
                NSIndexPath *matchingIndexdPath = [NSIndexPath indexPathForRow:counter inSection:0];
                [self tableView:self.tableView didSelectRowAtIndexPath:matchingIndexdPath];
                break;
            }
            counter += 1;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kStreamsSegue] || [segue.identifier isEqualToString:kStreamsNASegue])
    {
        StreamsViewController *vc = segue.destinationViewController;
        vc.selectedGroup = self.selectedGroup;
        vc.backgroundImage = self.posterImageDictionary[self.selectedGroup.name];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *showDict = self.favorites[indexPath.row];
    NSString *favName = showDict[@"name"];
    NSString *imdbID = showDict[@"imdbID"];
    StreamingGroup *favoriteGroup = [[StreamingGroup alloc] initWithName:favName];
    favoriteGroup.isFavorite = YES;
        
    NSMutableArray *addedTitles = @[].mutableCopy;
    
    for (StreamInfo *streamInfo in self.vodGroup.streams)
    {
        if ([streamInfo.name containsString:favName] && [addedTitles indexOfObject:streamInfo.name] == NSNotFound)
        {
            streamInfo.favoriteGroupName = favName;
            streamInfo.imdbID = imdbID;
            [favoriteGroup.streams addObject:streamInfo];
            [addedTitles addObject:streamInfo.name];
        }
    }

    NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)];
    [favoriteGroup.streams sortUsingDescriptors:@[nameSortDescriptor]];
    
    self.selectedGroup = favoriteGroup;
    
    if (self.deepLinkShowName)
    {
        self.deepLinkShowName = nil;
        [self performSegueWithIdentifier:kStreamsNASegue sender:nil];
    }
    else
    {
        [self performSegueWithIdentifier:kStreamsSegue sender:nil];
    }
}

- (void)loadPosterImageForShow:(NSDictionary *)show
{
    NSURL *posterURL = [NSURL URLWithString:show[@"posterURL"]];
    NSString *showName = show[@"name"];
    
    if (!posterURL)
    {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:posterURL];
        UIImage *image = [UIImage imageWithData:imageData];
        
        if (!image)
        {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.posterImageDictionary[showName] = image;
            [self.tableView reloadData];
        });
        
    });
    
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableCellId];
    
    NSDictionary *showDict = self.favorites[indexPath.row];
    cell.textLabel.text = showDict[@"name"];

    UIImage *posterImage = self.posterImageDictionary[showDict[@"name"]];
    cell.imageView.image = posterImage;
    
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
