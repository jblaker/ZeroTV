//
//  SearchResultsController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/24/20.
//

#import "SearchResultsController.h"
#import "StreamInfo.h"
#import "BookmarkManager.h"

@interface SearchResultsController ()

@property (nonatomic, strong) NSMutableArray *filteredStreams;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;

@end

@implementation SearchResultsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpLongPressGesture];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"TableCell"];
}

- (void)setStreams:(NSArray *)streams
{
    _streams = streams;
    self.filteredStreams = streams.mutableCopy;
    [self.tableView reloadData];
}

- (void)setUpLongPressGesture
{
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandler:)];
    [self.view addGestureRecognizer:self.longPressRecognizer];
}

- (void)longPressHandler:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint location = [gesture locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        StreamInfo *stream = self.filteredStreams[indexPath.row];
        [self showMarkAsOptions:stream];
    }
}

- (void)showMarkAsOptions:(StreamInfo *)selectedStream
{
    if (!selectedStream)
    {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([BookmarkManager streamIsBookmarked:selectedStream])
    {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Remove Bookmark" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [BookmarkManager removeBookmarkForStream:selectedStream];
        }]];
    }
    else
    {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Add Bookmark" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [BookmarkManager addBookmarkForStream:selectedStream];
        }]];
    }

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredStreams.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableCell"];
    
    StreamInfo *streamInfo = self.filteredStreams[indexPath.row];
    
    cell.textLabel.text = streamInfo.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    StreamInfo *streamInfo = self.filteredStreams[indexPath.row];
    
    [self.delegate didSelectStream:streamInfo];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *search = searchController.searchBar.text;
    
    if ([search isEqualToString:@""])
    {
        self.filteredStreams = self.streams.mutableCopy;
    }
    else
    {
        NSMutableArray *filteredResults = @[].mutableCopy;
        
        for (StreamInfo *info in self.streams)
        {
            if ([info.name.lowercaseString containsString:search.lowercaseString])
            {
                [filteredResults addObject:info];
            }
        }
        
        self.filteredStreams = filteredResults;
    }
    
    [self.tableView reloadData];
}

@end
