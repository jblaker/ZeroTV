//
//  StreamsViewController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "StreamsViewController.h"
#import "StreamingGroup.h"
#import "StreamInfo.h"
#import "SubtitlesViewController.h"
#import "OpenSubtitlesAdapter.h"
#import "SearchResultsController.h"
#import "UIViewController+Additions.h"
#import "EpisodeManager.h"
#import "CacheManager.h"

#import "VLCPlaybackService.h"
#import "VLCFullscreenMovieTVViewController.h"

@import TVVLCKit;
@import AVKit;

static NSString * const kTableCellId = @"TableViewCell";
static NSString * const kSubtitleOptionsSegueId = @"SubtitleSelection";
NSString * const kStreamPlaybackSegueId = @"StreamPlayback";

@interface StreamsViewController ()<UITableViewDelegate, UITableViewDataSource, SubtitlesViewControllerDelegate, SearchResultsControllerDelegate, VLCMediaDelegate, AVAssetResourceLoaderDelegate>

@property (nonatomic, weak) IBOutlet UIButton *searchButton;

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) SearchResultsController *searchResultsController;
@property (nonatomic, strong) StreamInfo *selectedStream;
@property (nonatomic, strong) UITapGestureRecognizer *menuButtonRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) VLCMedia *mediaItem;
@property (nonatomic, strong) AVPlayerViewController *avpvc;
@property (nonatomic, strong) NSData *customManifestData;

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

    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kTableCellId];
    
    [self setUpLongPressGesture];
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

- (StreamInfo *)streamInfoForTitle:(NSString *)title inArray:(NSArray *)array
{
    NSPredicate *namePredicate = [NSPredicate predicateWithFormat:@"name == %@", title];
    return [array filteredArrayUsingPredicate:namePredicate].firstObject;
}

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    if (self.tableView && self.searchButton)
    {
        return @[self.tableView, self.searchButton];
    }
    return @[];
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

- (void)mediaDidFinishParsing:(VLCMedia *)aMedia
{
    NSInteger lengthInMiliseconds = aMedia.length.intValue;
    if (lengthInMiliseconds > 0)
    {
        NSInteger lengthInSeconds = lengthInMiliseconds/1000;
        
        NSString *manifestContent = @"#EXTM3U\n";
        manifestContent = [manifestContent stringByAppendingString:@"#EXT-X-PLAYLIST-TYPE:VOD\n"];
        manifestContent = [manifestContent stringByAppendingFormat:@"#EXT-X-TARGETDURATION:%li.0\n", lengthInSeconds];
        manifestContent = [manifestContent stringByAppendingFormat:@"#EXTINF:%li.0\n", lengthInSeconds];
        manifestContent = [manifestContent stringByAppendingFormat:@"%@\n", self.selectedStream.streamURL];
        manifestContent = [manifestContent stringByAppendingString:@"#EXT-X-ENDLIST"];
        
        self.customManifestData = [manifestContent dataUsingEncoding:NSUTF8StringEncoding];
        
        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:@"zerotv://loadCustomManifest"]];
        [asset.resourceLoader setDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        playerItem.preferredForwardBufferDuration = lengthInSeconds;
        
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];

        self.avpvc = [AVPlayerViewController new];
        self.avpvc.player = player;
        
        [player play];
        
        [self.navigationController pushViewController:self.avpvc animated:YES];
    }
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURLResponse *updatedResponse = [[NSURLResponse alloc] initWithURL:[NSURL URLWithString:self.selectedStream.streamURL] MIMEType:@"application/x-mpegURL" expectedContentLength:self.customManifestData.length textEncodingName:nil];
    
    loadingRequest.response = updatedResponse;
    [loadingRequest.dataRequest respondWithData:self.customManifestData];
    [loadingRequest finishLoading];
    
    return YES;
}

- (void)setUpPlayer:(StreamInfo *)selectedStream
{
    NSURL *url = [NSURL URLWithString:selectedStream.streamURL];

    if (!url)
    {
        NSLog(@"Couldn't create URL!");
        return;
    }
    
    self.mediaItem = [VLCMedia mediaWithURL:url];
    self.mediaItem.delegate = self;
    [self.mediaItem parseWithOptions:VLCMediaParseNetwork];
    
//    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
//    VLCMedia *media = [VLCMedia mediaWithURL:url];
//    VLCMediaList *medialist = [[VLCMediaList alloc] init];
//    [medialist addMedia:media];
//
//    __weak typeof(self) weakSelf = self;
//    [vpc playMediaList:medialist hasSubs:selectedStream.didDownloadSubFile completion:^(BOOL success, float playbackPosition) {
//
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//
//        if (success)
//        {
//            NSLog(@"Video playback successful, %f complete", playbackPosition);
//            [EpisodeManager episodeDidComplete:strongSelf.selectedStream withPlaybackPosition:playbackPosition];
//            [strongSelf.tableView reloadData];
//        }
//        else
//        {
//            NSLog(@"Video did not play successfully");
//        }
//
//    }];
//
//    [self performSegueWithIdentifier:kStreamPlaybackSegueId sender:nil];
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

- (void)handleOpenSubtitlesResponse:(NSDictionary *)response
{
    NSArray *subtitleOptions = [OpenSubtitlesAdapter englishSubtitlesFromSearchResponse:response];
    
    if (subtitleOptions.count == 0)
    {
        //[self setUpPlayer:self.selectedStream];
        [self performSegueWithIdentifier:kSubtitleOptionsSegueId sender:nil];
    }
    else
    {
        self.selectedStream.subtitleOptions = subtitleOptions;
        [self performSegueWithIdentifier:kSubtitleOptionsSegueId sender:nil];
    }
}

- (void)setUpMenuTapGesture
{
    self.menuButtonRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuButtonHandler:)];
    self.menuButtonRecognizer.numberOfTapsRequired = 1;
    self.menuButtonRecognizer.allowedPressTypes = @[ @(UIPressTypeMenu) ];
    [self.searchController.view addGestureRecognizer:self.menuButtonRecognizer];
}

- (void)setUpLongPressGesture
{
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandler:)];
    //self.longPressRecognizer.minimumPressDuration = 1;
    [self.view addGestureRecognizer:self.longPressRecognizer];
}

- (void)showMarkAsOptions:(StreamInfo *)selectedStream
{
    if (!selectedStream)
    {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Mark as watched" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [EpisodeManager markAsWatched:selectedStream];
        [self.tableView reloadData];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Mark as un-watched" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [EpisodeManager markAsUnwatched:selectedStream];
        [self.tableView reloadData];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - IBAction

- (void)menuButtonHandler:(UITapGestureRecognizer *)gesture
{
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.searchController.view removeGestureRecognizer:self.menuButtonRecognizer];
}

- (void)longPressHandler:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint location = [gesture locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        StreamInfo *stream = self.selectedGroup.streams[indexPath.row];
        [self showMarkAsOptions:stream];
    }
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    self.selectedStream = self.selectedGroup.streams[indexPath.row];
    
    if (self.selectedStream.isVOD)
    {
        [self checkForCaptions];
    }
    else
    {
        [self setUpPlayer:self.selectedStream];
    }
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

    [self showErrorAlert:error completionHandler:^{
        [self dismissViewControllerAnimated:YES completion:^{
            [self setUpPlayer:self.selectedStream];
        }];
    }];
}

- (void)selectedElementarySubtitleAtIndex:(NSInteger)index
{
    // NO-OP
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
