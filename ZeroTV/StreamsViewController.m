//
//  StreamsViewController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "StreamsViewController.h"
#import "StreamingGroup.h"
#import "StreamInfo.h"
#import "SearchResultsController.h"
#import "EpisodeManager.h"
#import "BookmarkManager.h"

@interface StreamsViewController ()<UITableViewDelegate, UITableViewDataSource, SearchResultsControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *searchButton;

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) SearchResultsController *searchResultsController;
@property (nonatomic, strong) UITapGestureRecognizer *menuButtonRecognizer;

@end

@implementation StreamsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.selectedGroup.name;
    
    if (self.selectedGroup.streams.count > 10 && !self.selectedGroup.isFavorite)
    {
        self.searchButton.hidden = NO;
    }
    else
    {
        self.searchButton.hidden = YES;
    }
}

- (void)buildBackgroundView
{
    if (self.backgroundImage)
    {
        UIImageView *backgroundView = [[UIImageView alloc] initWithImage:self.backgroundImage];
        backgroundView.contentMode = UIViewContentModeScaleAspectFill;
        backgroundView.frame = self.view.frame;
        [self.view addSubview:backgroundView];
        [self.view sendSubviewToBack:backgroundView];
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *effectsView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        effectsView.frame = self.view.frame;
        [self.view insertSubview:effectsView aboveSubview:backgroundView];
    }
    else
    {
        [super buildBackgroundView];
    }
}

- (StreamInfo *)streamAtIndexPath:(NSIndexPath *)indexPath
{
    return self.selectedGroup.streams[indexPath.row];
}

- (void)setSelectedGroup:(StreamingGroup *)selectedGroup
{
    if (selectedGroup.isFavorite)
    {
        NSMutableArray *sdStreams = @[].mutableCopy;
        NSMutableArray *hdStreams = @[].mutableCopy;
        
        for (StreamInfo *streamInfo in selectedGroup.streams)
        {
            if ([streamInfo.name hasPrefix:@"SD :"])
            {
                [sdStreams addObject:streamInfo];
            }
            if ([streamInfo.name hasPrefix:@"HD :"])
            {
                [hdStreams addObject:streamInfo];
            }
        }
        
        selectedGroup.streams = [hdStreams arrayByAddingObjectsFromArray:sdStreams].mutableCopy;
        
        _selectedGroup = selectedGroup;
    }
    else
    {
        _selectedGroup = selectedGroup;
    }

}

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    if (self.tableView && self.searchButton)
    {
        return @[self.tableView, self.searchButton];
    }
    return @[];
}

- (void)setUpMenuTapGesture
{
    self.menuButtonRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuButtonHandler:)];
    self.menuButtonRecognizer.numberOfTapsRequired = 1;
    self.menuButtonRecognizer.allowedPressTypes = @[ @(UIPressTypeMenu) ];
    [self.searchController.view addGestureRecognizer:self.menuButtonRecognizer];
}

- (void)showMarkAsOptions:(StreamInfo *)selectedStream
{
    if (!selectedStream)
    {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([self.selectedGroup.name isEqualToString:@"Movie VOD"] || [self.selectedGroup.name isEqualToString:@"TV VOD"])
    {
        if ([BookmarkManager streamIsBookmarked:selectedStream])
        {
            [alertController addAction:[UIAlertAction actionWithTitle:@"Remove Bookmark" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [BookmarkManager removeBookmarForStream:selectedStream];
            }]];
        }
        else
        {
            [alertController addAction:[UIAlertAction actionWithTitle:@"Add Bookmark" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [BookmarkManager addBookmarkForStream:selectedStream];
            }]];
        }
    }
    
    if ([self.selectedGroup.name isEqualToString:@"TV VOD"] || self.selectedGroup.isFavorite)
    {
        if ([EpisodeManager episodeWasWatched:selectedStream])
        {
            [alertController addAction:[UIAlertAction actionWithTitle:@"Mark as un-watched" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [EpisodeManager markAsUnwatched:selectedStream];
                [self.tableView reloadData];
            }]];
        }
        else
        {
            [alertController addAction:[UIAlertAction actionWithTitle:@"Mark as watched" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [EpisodeManager markAsWatched:selectedStream];
                [self.tableView reloadData];
            }]];
        }
    }

    if (alertController.actions.count > 0)
    {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - IBAction

- (void)menuButtonHandler:(UITapGestureRecognizer *)gesture
{
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.searchController.view removeGestureRecognizer:self.menuButtonRecognizer];
}

- (IBAction)searchButtonPressed:(id)sender
{
    if (!self.searchResultsController)
    {
        self.searchResultsController = [[SearchResultsController alloc] initWithStyle:UITableViewStylePlain];
        self.searchResultsController.streams = self.selectedGroup.streams;
        self.searchResultsController.delegate = self;
    }
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultsController];
    self.searchController.searchResultsUpdater = self.searchResultsController;
    self.searchController.obscuresBackgroundDuringPresentation = YES;

    [self setUpMenuTapGesture];
    
    [self presentViewController:self.searchController animated:NO completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.selectedGroup.streams.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableCellId];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    StreamInfo *streamInfo = self.selectedGroup.streams[indexPath.row];
    
    cell.textLabel.text = streamInfo.name;
    
    BOOL watched = [EpisodeManager episodeWasWatched:streamInfo];
    
    if (watched)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - SearchResultsControllerDelegate

- (void)didSelectStream:(StreamInfo *)streamInfo
{
    self.selectedStream = streamInfo;
    
    [self dismissViewControllerAnimated:NO completion:^{
        
        if (self.selectedStream.isVOD)
        {
            [self checkForCaptions];
        }
        else
        {
            [self setUpPlayer:self.selectedStream];
        }

    }];
}

@end
