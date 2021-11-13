//
//  EPGManager.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 11/12/21.
//

#import "EPGManager.h"
#import "CacheManager.h"
#import "EPGChannel.h"
#import "EPGProgram.h"

const NSNotificationName kZeroTVEPAMangerReadyNotification = @"kZeroTVEPAMangerReadyNotification";

typedef NS_ENUM(NSUInteger, LookingForType)
{
    LookingForTypeDisplayName = 0,
    LookingForTypeProgram,
    LookingForTypeDescription
};

@interface EPGManager ()<NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *channels;

@property (nonatomic, strong) EPGChannel *currentChannel;
@property (nonatomic, strong) EPGProgram *currentProgram;

@property (nonatomic, assign) LookingForType lookingForType;

@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@end

@implementation EPGManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static EPGManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [EPGManager new];
        manager.numberFormatter = [NSNumberFormatter new];
        manager.numberFormatter.numberStyle = NSNumberFormatterNoStyle;

    });
    return manager;
}

+ (void)fetchEPGData:(BOOL)useCached
{
    [EPGManager.sharedManager fetchEPGData:useCached];
}

+ (NSArray *)programsForChannelName:(NSString *)channelName
{
    for (EPGChannel *channel in EPGManager.sharedManager.channels.copy)
    {
//        if ([channel.channelName.lowercaseString containsString:@"amc"])
//        {
//            NSLog(@"");
//        }
        if ([channel.channelName.lowercaseString isEqualToString:channelName.lowercaseString])
        {
            return channel.programs;
        }
    }
    
    // If channel name has USA prefix try with US instead
    if ([channelName hasPrefix:@"USA:"])
    {
        NSString *modifiedChannelName = [channelName stringByReplacingOccurrencesOfString:@"USA:" withString:@"US:"];
        return [EPGManager programsForChannelName:modifiedChannelName];
    }
    
    return nil;
}

+ (NSTimeInterval)timeIntervalFromString:(NSString *)string
{
    NSNumberFormatter *formatter = EPGManager.sharedManager.numberFormatter;
    NSNumber *number = [formatter numberFromString:string];
    return number.longLongValue;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.channels = @[].mutableCopy;
    }
    return self;
}

- (void)fetchEPGData:(BOOL)useCached
{
    if (useCached)
    {
        NSData *cachedData = [CacheManager cachedDataNamed:kCachedEPAFilename];
        if (cachedData)
        {
            NSLog(@"Using cached EPG data");
            [self parseEPGData:cachedData];
            return;
        }
    }
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    NSURL *epgURL = [NSURL URLWithString:dict[@"EPAURL"]];
    
    __weak typeof(self) weakSelf = self;
    [[NSURLSession.sharedSession dataTaskWithURL:epgURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error)
        {
            NSLog(@"Error: %@", error.localizedDescription);
            return;
        }
        
        [CacheManager cacheData:data filename:kCachedEPAFilename];
        
        [weakSelf parseEPGData:data];
            
    }] resume];
}

- (void)parseEPGData:(NSData *)epgData
{
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:epgData];
    xmlParser.delegate = self;
    
    if ([xmlParser parse])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kZeroTVEPAMangerReadyNotification object:nil userInfo:@{@"success":@(YES)}];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kZeroTVEPAMangerReadyNotification object:nil userInfo:@{@"success":@(NO)}];
    }
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"Error: %@", parseError.localizedDescription);
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"channel"])
    {
        self.currentChannel = [EPGChannel new];
        self.currentChannel.channelId = attributeDict[@"id"];
        [self.channels addObject:self.currentChannel];
    }
    
    if ([elementName isEqualToString:@"display-name"])
    {
        self.lookingForType = LookingForTypeDisplayName;
    }
    
    if ([elementName isEqualToString:@"programme"])
    {
        self.currentProgram = [EPGProgram new];
        
        if (attributeDict[@"start_timestamp"] && attributeDict[@"stop_timestamp"])
        {
        self.currentProgram.startTimestamp = [EPGManager timeIntervalFromString:attributeDict[@"start_timestamp"]];
        self.currentProgram.stopTimestamp = [EPGManager timeIntervalFromString:attributeDict[@"stop_timestamp"]];
        }
        
        self.lookingForType = LookingForTypeProgram;
    }
    
    if ([elementName isEqualToString:@"desc"])
    {
        self.lookingForType = LookingForTypeDescription;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (string.length > 1)
    {
        if (self.lookingForType == LookingForTypeDisplayName)
        {
            self.currentChannel.channelName = string;
        }
        
        if (self.lookingForType == LookingForTypeDescription && self.currentProgram.programName)
        {
            self.currentProgram.programDescription = string;
            [self.currentChannel.programs addObject:self.currentProgram];
        }
        
        if (self.lookingForType == LookingForTypeProgram)
        {
            self.currentProgram.programName = string;
        }
    }
}

@end
