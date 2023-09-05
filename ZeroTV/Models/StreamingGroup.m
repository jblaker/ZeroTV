//
//  StreamingGroup.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "StreamingGroup.h"
#import "StreamInfo.h"

#define LOG_TIME 0

@interface StreamingGroup ()

@property (nonatomic, assign) BOOL hasFilteredStreams;
@property (nonatomic, strong) NSMutableArray *filteredStreams;

@end

@implementation StreamingGroup

- (instancetype)init
{
    return [self initWithName:@"???"];
}

- (instancetype)initWithName:(NSString *)name
{
    if (self = [super init])
    {
        _name = name;
        _streams = @[].mutableCopy;
    }
    return self;
}

- (void)filterDuplicates:(void (^)(void))completion
{
    if (self.hasFilteredStreams)
    {
        if (completion)
        {
            completion();
        }
        return;
    }
    
    self.filteredStreams = @[].mutableCopy;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
#if LOG_TIME
        NSTimeInterval startTime = [NSDate date].timeIntervalSince1970;
#endif
        
        self.streams = [self.streams sortedArrayUsingComparator:^NSComparisonResult(StreamInfo *  _Nonnull obj1, StreamInfo *  _Nonnull obj2) {
            return [obj1.name compare:obj2.name];
        }].mutableCopy;

        for (StreamInfo *stream in self.streams)
        {
            if (self.filteredStreams.count == 0)
            {
                [self.filteredStreams addObject:stream];
                continue;
            }
            
            NSInteger matchingIndex = [self streamInfoBinarySearchWithLowerBounds:0 upperBounds:self.filteredStreams.count-1 streamInfo:stream];

            if (matchingIndex == NSNotFound)
            {
                [self.filteredStreams addObject:stream];
            }
            else
            {
                StreamInfo *matchingStream = self.filteredStreams[matchingIndex];
                [matchingStream.alternateStreamURLs addObject:stream.streamURL];
            }
        }
        
        self.filteredStreams = [self.filteredStreams sortedArrayUsingComparator:^NSComparisonResult(StreamInfo *  _Nonnull obj1, StreamInfo *  _Nonnull obj2) {
            return [@(obj1.index) compare:@(obj2.index)];
        }].mutableCopy;
        
#if LOG_TIME
        NSTimeInterval endTime = [NSDate date].timeIntervalSince1970;
        NSTimeInterval timeDifference = endTime - startTime;
        NSInteger countDifference = self.streams.count - self.filteredStreams.count;
        NSLog(@"Filtered %li duplicates in %f seconds", (long)countDifference, timeDifference);
#endif
        
        self.streams = self.filteredStreams.mutableCopy;
        self.filteredStreams = nil;
        self.hasFilteredStreams = YES;
        
        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (NSInteger)streamInfoBinarySearchWithLowerBounds:(NSInteger)lowerBounds upperBounds:(NSInteger)upperBounds streamInfo:(StreamInfo *)streamInfo
{
    if (lowerBounds > upperBounds)
    {
        return NSNotFound;
    }
    
    NSInteger mid = lowerBounds + (upperBounds - lowerBounds) / 2;

    StreamInfo *midStream = self.filteredStreams[mid];
    
    NSComparisonResult comparison = [streamInfo.name compare:midStream.name];
    
    if (comparison == NSOrderedSame)
    {
        return mid;
    }
    
    if (comparison == NSOrderedAscending)
    {
        //NSLog(@"%@ comes before search item %@", midStream.name.lowercaseString, streamInfo.name.lowercaseString);
        return [self streamInfoBinarySearchWithLowerBounds:lowerBounds upperBounds:upperBounds-1 streamInfo:streamInfo];
    }
    
    //NSLog(@"%@ comes after search item %@", midStream.name.lowercaseString, streamInfo.name.lowercaseString);
    return [self streamInfoBinarySearchWithLowerBounds:mid+1 upperBounds:upperBounds streamInfo:streamInfo];
    
}

@end
