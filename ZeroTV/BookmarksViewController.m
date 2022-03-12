//
//  BookmarksViewController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 3/12/22.
//

#import "BookmarksViewController.h"
#import "BookmarkManager.h"
#import "StreamInfo.h"
#import "OpenSubtitlesAdapter.h"
#import "UIViewController+Additions.h"
#import "SubtitlesViewController.h"

#import "VLCPlaybackService.h"
#import "VLCFullscreenMovieTVViewController.h"

static NSString * const kTableCellId = @"TableViewCell";
static NSString * const kSubtitleOptionsSegueId = @"SubtitleSelection";
static NSString * const kStreamPlaybackSegueId = @"StreamPlayback";

@interface BookmarksViewController ()<SubtitlesViewControllerDelegate>

@property (nonatomic, strong) NSArray *bookmarks;
@property (nonatomic, strong) StreamInfo *selectedStream;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;

@end

@implementation BookmarksViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Bookmarks";
    
    [self setUpLongPressGesture];
    
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kTableCellId];
    
    self.bookmarks = [BookmarkManager bookmarks];
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSubtitleOptionsSegueId])
    {
        SubtitlesViewController *vc = segue.destinationViewController;
        vc.selectedStream = self.selectedStream;
        vc.delegate = self;
    }
    
    if ([segue.identifier isEqualToString:kStreamPlaybackSegueId])
    {
        VLCFullscreenMovieTVViewController *vc = segue.destinationViewController;
        vc.selectedStream = self.selectedStream;
    }
}

- (void)checkForCaptions
{
    // We already have captions, no need to check again
    if (self.selectedStream.subtitleOptions.count > 0)
    {
        [self performSegueWithIdentifier:kSubtitleOptionsSegueId sender:nil];
        return;
    }
    
    [self showSpinner:YES];

    // Name format will be similar to:
    // HD : The Mandalorian S01E01
    NSArray *nameParts = [self.selectedStream.name componentsSeparatedByString:@" : "];
    NSString *episodeName = nameParts.lastObject;
    
    if (self.selectedStream.searchTerm && self.selectedStream.favoriteGroupName)
    {
        episodeName = [episodeName stringByReplacingOccurrencesOfString:self.selectedStream.favoriteGroupName withString:self.selectedStream.searchTerm];
    }
    
    __weak typeof(self) weakSelf = self;
    
    [OpenSubtitlesAdapter subtitleSearch:episodeName completionHandler:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf showSpinner:NO];
        
        if (error)
        {
            [strongSelf showErrorAlert:error completionHandler:^{
                [strongSelf setUpPlayer:strongSelf.selectedStream];
            }];
        }
        else
        {
            [weakSelf handleOpenSubtitlesResponse:response];
        }
        
    }];
}

- (void)setUpPlayer:(StreamInfo *)selectedStream
{
    NSURL *url = [NSURL URLWithString:selectedStream.streamURL];

    if (!url)
    {
        NSLog(@"Couldn't create URL!");
        return;
    }
    
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMedia *media = [VLCMedia mediaWithURL:url];
    VLCMediaList *medialist = [[VLCMediaList alloc] init];
    [medialist addMedia:media];
    
    __weak typeof(self) weakSelf = self;
    [vpc playMediaList:medialist hasSubs:selectedStream.didDownloadSubFile completion:^(BOOL success, float playbackPosition) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (!success)
        {
            [strongSelf dismissViewControllerAnimated:NO completion:^{
                NSLog(@"Video did not play successfully");
            }];
        }

    }];
    
    [self performSegueWithIdentifier:kStreamPlaybackSegueId sender:nil];
}

- (void)handleOpenSubtitlesResponse:(NSDictionary *)response
{
    NSArray *subtitleOptions = [OpenSubtitlesAdapter englishSubtitlesFromSearchResponse:response];
    
    if (subtitleOptions.count == 0)
    {
        [self performSegueWithIdentifier:kSubtitleOptionsSegueId sender:nil];
    }
    else
    {
        self.selectedStream.subtitleOptions = subtitleOptions;
        [self performSegueWithIdentifier:kSubtitleOptionsSegueId sender:nil];
    }
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
        StreamInfo *stream = self.bookmarks[indexPath.row];
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
            [BookmarkManager removeBookmarForStream:selectedStream];
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.bookmarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableCellId];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    StreamInfo *streamInfo = self.bookmarks[indexPath.row];
    
    cell.textLabel.text = streamInfo.name;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    self.selectedStream = self.bookmarks[indexPath.row];
    
    [self checkForCaptions];
}

#pragma mark - SubtitlesViewControllerDelegate

- (void)didConfigureSubtitles:(BOOL)didConfigure
{
    self.selectedStream.didDownloadSubFile = didConfigure;
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self setUpPlayer:self.selectedStream];
    }];
}

- (void)didEncounterError:(NSError *)error
{
    self.selectedStream.didDownloadSubFile = NO;

    [self dismissViewControllerAnimated:YES completion:^{
        [self showErrorAlert:error completionHandler:^{
            [self setUpPlayer:self.selectedStream];
        }];
    }];
}

- (void)selectedElementarySubtitleAtIndex:(NSInteger)index
{
    // NO-OP
}

@end
