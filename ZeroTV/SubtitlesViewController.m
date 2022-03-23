//
//  SubtitlesViewController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "SubtitlesViewController.h"
#import "StreamsViewController.h"
#import "OpenSubtitlesAdapter.h"
#import "DownloadUploadManager.h"
#import "CacheManager.h"

#import "VLCPlaybackService.h"
#import "VLCFullscreenMovieTVViewController.h"

@import TVVLCKit;

@interface SubtitlesViewController ()<UITableViewDelegate, UITableViewDataSource>

@end

@implementation SubtitlesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Subtitles";
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 2;
    }
    
    if (section == 1)
    {
        return self.selectedStream.subtitleOptions.count;
    }
    
    if (section == 2)
    {
        return self.selectedStream.isVOD ? 0 : self.videoSubTitlesNames.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableCellId];
    
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0)
        {
            cell.textLabel.text = @"None";
            cell.detailTextLabel.text = nil;
        }
        if (indexPath.row == 1)
        {
            cell.textLabel.text = @"Use Uploaded";
            cell.detailTextLabel.text = nil;
        }
    }
    
    if (indexPath.section == 1)
    {
        NSDictionary *option = self.selectedStream.subtitleOptions[indexPath.row];
        
        NSString *subName = @"???";
        NSString *comments = nil;
        
        if ([option[@"release"] isKindOfClass:NSString.class])
        {
            subName = option[@"release"];
        }
        
        if ([option[@"comments"] isKindOfClass:NSString.class])
        {
            comments = option[@"comments"];
        }
        
        cell.textLabel.text = subName;
        cell.detailTextLabel.text = comments;
    }
    
    if (indexPath.section == 2)
    {
        cell.textLabel.text = self.videoSubTitlesNames[indexPath.row];
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0)
    {
        if (indexPath.row == 0)
        {
            [self.delegate didConfigureSubtitles:NO];
        }
        if (indexPath.row == 1)
        {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
            NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];
            NSDictionary *fauxResponse = @{
                @"link":dict[@"UploadedSubtitleFileURL"]
            };
            [self fetchSubtitleData:fauxResponse];
        }
    }
    
    if (indexPath.section == 1)
    {
        NSDictionary *option = self.selectedStream.subtitleOptions[indexPath.row];
        
        [self fetchSubtitleFileDownloadURL:option];
    }
    
    if (indexPath.section == 2)
    {
        [self.delegate selectedElementarySubtitleAtIndex:indexPath.row];
    }
}

- (void)fetchSubtitleFileDownloadURL:(NSDictionary *)selectedSubtitle
{
    [self showSpinner:YES];

    __weak typeof(self) weakSelf = self;
    
    [OpenSubtitlesAdapter subtitleDownload:selectedSubtitle completionHandler:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (error)
        {
            [strongSelf showSpinner:NO];
            [strongSelf.delegate didEncounterError:error];
        }
        else
        {
            [strongSelf fetchSubtitleData:response];
        }
        
    }];
}

- (void)fetchSubtitleData:(NSDictionary *)response
{
    __weak typeof(self) weakSelf = self;
    
    NSURL *downloadURL = [NSURL URLWithString:response[@"link"]];

    [DownloadUploadManager fetchSubtitleFileData:downloadURL completionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf showSpinner:NO];
        
        if (error)
        {
            [strongSelf.delegate didEncounterError:error];
        }
        else
        {
            NSError *error = [CacheManager cacheData:data filename:kCachedSubFilename];
            
            if (error)
            {
                [strongSelf.delegate didEncounterError:error];
            }
            else
            {
                [strongSelf.delegate didConfigureSubtitles:YES];
            }
        }
        
    }];
}

@end
