//
//  SearchResultsController.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/24/20.
//

#import "SearchResultsController.h"
#import "StreamInfo.h"

@interface SearchResultsController ()

@property (nonatomic, strong) NSMutableArray *filteredStreams;

@end

@implementation SearchResultsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"TableCell"];
}

- (void)setStreams:(NSArray *)streams
{
    _streams = streams;
    self.filteredStreams = streams.mutableCopy;
    [self.tableView reloadData];
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
