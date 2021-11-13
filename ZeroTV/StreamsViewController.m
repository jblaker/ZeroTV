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
#import "EPGManager.h"
#import "EPGProgram.h"

#import "VLCPlaybackService.h"
#import "VLCFullscreenMovieTVViewController.h"

@import TVVLCKit;

static NSString * const kTableCellId = @"TableViewCell";
static NSString * const kSubtitleOptionsSegueId = @"SubtitleSelection";
NSString * const kStreamPlaybackSegueId = @"StreamPlayback";

@interface StreamsViewController ()<UITableViewDelegate, UITableViewDataSource, SubtitlesViewControllerDelegate, SearchResultsControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *searchButton;

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) SearchResultsController *searchResultsController;
@property (nonatomic, strong) StreamInfo *selectedStream;
@property (nonatomic, strong) UITapGestureRecognizer *menuButtonRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;

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

- (void)findProgramForCurrentTime:(NSArray<EPGProgram *> *)programs
{
    EPGProgram *currentProgram;

    for (EPGProgram *program in programs)
    {
        NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
        
        if (currentTime >= program.startTimestamp && currentTime <= program.stopTimestamp)
        {
            currentProgram = program;
            break;
        }
    }
    
    // Determine furthest date out
//    EPGProgram *lastProgram = programs.lastObject;
//    NSDate *date = [NSDate dateWithTimeIntervalSince1970:lastProgram.startTimestamp];
//    NSDateFormatter *dateFormatter = [NSDateFormatter new];
//    dateFormatter.dateStyle = NSDateFormatterLongStyle;
//    dateFormatter.timeStyle = NSDateFormatterLongStyle;
//    NSLog(@"__DEBUG %@", [dateFormatter stringFromDate:date]);
    
    if (currentProgram)
    {
        // TODO: Set up a timer or something using the stopTimestamp to update the program name
        self.selectedStream.programName = currentProgram.programName;
    }
}

- (void)setUpPlayer:(StreamInfo *)selectedStream
{
    NSURL *url = [NSURL URLWithString:selectedStream.streamURL];

    if (!url)
    {
        NSLog(@"Couldn't create URL!");
        return;
    }
    
    if (!selectedStream.isVOD)
    {
        NSArray *programs = [EPGManager programsForChannelName:selectedStream.name];
        [self findProgramForCurrentTime:programs];
    }

    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMedia *media = [VLCMedia mediaWithURL:url];
    VLCMediaList *medialist = [[VLCMediaList alloc] init];
    [medialist addMedia:media];
    
    __weak typeof(self) weakSelf = self;
    [vpc playMediaList:medialist hasSubs:selectedStream.didDownloadSubFile completion:^(BOOL success, float playbackPosition) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (success)
        {
            NSLog(@"Video playback successful, %f complete", playbackPosition);
            [EpisodeManager episodeDidComplete:strongSelf.selectedStream withPlaybackPosition:playbackPosition];
            [strongSelf.tableView reloadData];
        }
        else
        {
            [self dismissViewControllerAnimated:NO completion:^{
                NSLog(@"Video did not play successfully");
            }];
        }

    }];
    
    [self performSegueWithIdentifier:kStreamPlaybackSegueId sender:nil];
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
