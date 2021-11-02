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
@property (nonatomic, strong) NSData *masterManifestData;
@property (nonatomic, strong) NSData *renditionManifestData;
@property (nonatomic, strong) NSData *vttManifestData;
@property (nonatomic, copy) NSString *subtitleURL;

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
        [self buildCustomManifestWithDuration:lengthInSeconds];
        [self showSpinner:NO];
    }
}

- (void)buildCustomManifestWithDuration:(NSInteger)duration
{
    // Build Master Manifest
    NSString *manifestContent = @"#EXTM3U\n";
    if (self.selectedStream.didDownloadSubFile)
    {
        manifestContent = [manifestContent stringByAppendingString:@"#EXT-X-MEDIA:TYPE=SUBTITLES,NAME=\"English\",LANGUAGE=\"en\",DEFAULT=YES,AUTOSELECT=YES,FORCED=NO,URI=\"zerotv://vtt.m3u8\",GROUP-ID=\"subs\"\n"];
        manifestContent = [manifestContent stringByAppendingString:@"#EXT-X-STREAM-INF:BANDWIDTH=1,SUBTITLES=\"subs\"\n"];
    }
    else
    {
        manifestContent = [manifestContent stringByAppendingString:@"#EXT-X-STREAM-INF:BANDWIDTH=1\n"];
    }
    manifestContent = [manifestContent stringByAppendingString:@"zerotv://rendition.m3u8\n"];
    
    self.masterManifestData = [manifestContent dataUsingEncoding:NSUTF8StringEncoding];
    
    // Build Rendition Manifest
    manifestContent = @"#EXTM3U\n";
    
    if (self.selectedStream.isVOD)
    {
        manifestContent = [manifestContent stringByAppendingString:@"#EXT-X-PLAYLIST-TYPE:VOD\n"];
    }
    else
    {
        //manifestContent = [manifestContent stringByAppendingString:@"#EXT-X-PLAYLIST-TYPE:EVENT\n"];
    }
    manifestContent = [manifestContent stringByAppendingFormat:@"#EXT-X-TARGETDURATION:%li\n", duration];
    manifestContent = [manifestContent stringByAppendingFormat:@"#EXTINF:%li,\n", duration];
    manifestContent = [manifestContent stringByAppendingFormat:@"%@\n", self.selectedStream.streamURL];
    
    if (self.selectedStream.isVOD)
    {
        manifestContent = [manifestContent stringByAppendingString:@"#EXT-X-ENDLIST\n"];
    }
    
    self.renditionManifestData = [manifestContent dataUsingEncoding:NSUTF8StringEncoding];
    
    // Build VTT Manifest
    manifestContent = @"#EXTM3U\n";
    manifestContent = [manifestContent stringByAppendingFormat:@"#EXT-X-TARGETDURATION:%li\n", duration];
    manifestContent = [manifestContent stringByAppendingFormat:@"#EXTINF:%li,\n", duration];
    manifestContent = [manifestContent stringByAppendingFormat:@"%@\n", self.subtitleURL];
    manifestContent = [manifestContent stringByAppendingString:@"#EXT-X-ENDLIST\n"];
    
    self.vttManifestData = [manifestContent dataUsingEncoding:NSUTF8StringEncoding];

    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:@"zerotv://master.m3u8"]];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    AVMutableMetadataItem *metadata = [AVMutableMetadataItem new];
    metadata.identifier = AVMetadataCommonIdentifierTitle;
    metadata.value = self.selectedStream.name;
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    playerItem.externalMetadata = @[metadata];
    playerItem.preferredForwardBufferDuration = duration / 2;
    
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    player.automaticallyWaitsToMinimizeStalling = NO;

    self.avpvc = [AVPlayerViewController new];
    self.avpvc.player = player;
    
    [self.navigationController pushViewController:self.avpvc animated:NO];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.avpvc.player play];
    });
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *url = loadingRequest.request.URL;
    
    if ([url.absoluteString isEqualToString:@"zerotv://master.m3u8"])
    {
        [loadingRequest.dataRequest respondWithData:self.masterManifestData];
        [loadingRequest finishLoading];
        
        return YES;
    }
    
    if ([url.absoluteString isEqualToString:@"zerotv://rendition.m3u8"])
    {
        [loadingRequest.dataRequest respondWithData:self.renditionManifestData];
        [loadingRequest finishLoading];
        
        return YES;
    }
    
    if ([url.absoluteString isEqualToString:@"zerotv://vtt.m3u8"])
    {
        [loadingRequest.dataRequest respondWithData:self.vttManifestData];
        [loadingRequest finishLoading];
        
        return YES;
    }
    
    return NO;
}

- (void)setUpPlayer:(StreamInfo *)selectedStream
{
    if (!selectedStream.isVOD)
    {
        [self buildCustomManifestWithDuration:0];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:selectedStream.streamURL];

    if (!url)
    {
        NSLog(@"Couldn't create URL!");
        return;
    }
    
    [self showSpinner:YES];
    
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

//- (void)didConfigureSubtitles:(BOOL)didConfigure
//{
//    self.selectedStream.didDownloadSubFile = didConfigure;
//
//    [self dismissViewControllerAnimated:YES completion:^{
//        [self setUpPlayer:self.selectedStream];
//    }];
//}

- (void)didFetchURLForSubtitle:(NSString *)subtitleURL
{
    self.subtitleURL = subtitleURL;
    
    [self dismissViewControllerAnimated:NO completion:^{
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
