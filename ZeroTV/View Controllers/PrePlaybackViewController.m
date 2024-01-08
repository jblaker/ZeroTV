//
//  PrePlaybackViewController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 3/23/22.
//

#import "PrePlaybackViewController.h"
#import "VLCPlaybackService.h"
#import "VLCFullscreenMovieTVViewController.h"
#import "StreamInfo.h"
#import "EpisodeManager.h"
#import "SubtitlesViewController.h"
#import "OpenSubtitlesAdapter.h"
#import "UIViewController+Additions.h"
#import "Bookmark+CoreDataProperties.h"

static NSString * const kSubtitleOptionsSegueId = @"SubtitleSelection";
static NSString * const kStreamPlaybackSegueId = @"StreamPlayback";

@interface PrePlaybackViewController ()<SubtitlesViewControllerDelegate>

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;

@end

@implementation PrePlaybackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kTableCellId];
    
    [self setUpLongPressGesture];
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
        id<GenericStream> stream = [self streamAtIndexPath:indexPath];
        [self showMarkAsOptions:stream];
    }
}

- (void)setUpPlayer:(id<GenericStream>)selectedStream
{
    if (selectedStream.alternateStreamURLs.count > 0)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Options" message:@"This video has multiple sources available." preferredStyle:UIAlertControllerStyleActionSheet];
        
        NSURL *url = [NSURL URLWithString:selectedStream.streamURL];
        if (url)
        {
            [alertController addAction:[UIAlertAction actionWithTitle:@"Option 1" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                //NSLog(@"Selected option %@", url.absoluteString);
                [self setUpPlayerWithURL:url];
            }]];
        }
        
        NSInteger counter = 2;
        for (NSString *urlStr in selectedStream.alternateStreamURLs)
        {
            NSURL *url = [NSURL URLWithString:urlStr];
            if (url)
            {
                NSString *optionName = [NSString stringWithFormat:@"Option %li", counter];
                [alertController addAction:[UIAlertAction actionWithTitle:optionName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    //NSLog(@"Selected option %@", url.absoluteString);
                    [self setUpPlayerWithURL:url];
                }]];
            }
            counter += 1;
        }
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        NSURL *url = [NSURL URLWithString:selectedStream.streamURL];

        if (!url)
        {
            //NSLog(@"Couldn't create URL!");
            return;
        }
        
        [self setUpPlayerWithURL:url];
    }
}

- (void)setUpPlayerWithURL:(NSURL *)url
{
    VLCPlaybackService *vpc = [VLCPlaybackService sharedInstance];
    VLCMedia *media = [VLCMedia mediaWithURL:url];
    
    __weak typeof(self) weakSelf = self;
    [vpc playMedia:media hasSubs:self.selectedStream.didDownloadSubFile completion:^(BOOL success, float playbackPosition) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (success)
        {
            //NSLog(@"Video playback successful, %f complete", playbackPosition);
            [EpisodeManager episodeDidComplete:strongSelf.selectedStream withPlaybackPosition:playbackPosition];
            [strongSelf.tableView reloadData];
        }
        else
        {
            [strongSelf dismissViewControllerAnimated:NO completion:^{
                //NSLog(@"Video did not play successfully");
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

- (void)showMarkAsOptions:(StreamInfo *)selectedStream
{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (StreamInfo *)streamAtIndexPath:(NSIndexPath *)indexPath
{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    self.selectedStream = [self streamAtIndexPath:indexPath];
    
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

@end
