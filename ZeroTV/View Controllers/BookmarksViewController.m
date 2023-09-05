//
//  BookmarksViewController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 3/12/22.
//

#import "BookmarksViewController.h"
#import "BookmarkManager.h"
#import "UIViewController+Additions.h"
#import "Bookmark+CoreDataProperties.h"
#import "GenericStream.h"

static NSString * const kSubtitleOptionsSegueId = @"SubtitleSelection";
static NSString * const kStreamPlaybackSegueId = @"StreamPlayback";

@interface BookmarksViewController ()

@property (nonatomic, strong) NSArray<id<GenericStream>> *bookmarks;

@end

@implementation BookmarksViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Bookmarks";

    self.bookmarks = [BookmarkManager bookmarks];
    [self.tableView reloadData];
}

- (void)showMarkAsOptions:(id<GenericStream>)selectedStream
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
            self.bookmarks = [BookmarkManager bookmarks];
            [self.tableView reloadData];
        }]];
    }
    else
    {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Add Bookmark" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [BookmarkManager addBookmarkForStream:selectedStream];
            self.bookmarks = [BookmarkManager bookmarks];
            [self.tableView reloadData];
        }]];
    }

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (id<GenericStream>)streamAtIndexPath:(NSIndexPath *)indexPath
{
    return self.bookmarks[indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.bookmarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableCellId];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    Bookmark *bookmark = (Bookmark *)self.bookmarks[indexPath.row];
    
    cell.textLabel.text = bookmark.name;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    self.selectedStream = (id<GenericStream>)self.bookmarks[indexPath.row];
    
    [self checkForCaptions];
}

@end
