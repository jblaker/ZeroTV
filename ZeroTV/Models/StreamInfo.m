//
//  StreamInfo.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "StreamInfo.h"

@interface StreamInfo ()<NSCoding>

@end

@implementation StreamInfo

- (instancetype)init
{
    return [self initWithName:@"???" streamURL:@""];
}

- (instancetype)initWithName:(NSString *)name streamURL:(NSString *)streamURL
{
    if (self = [super init])
    {
        _name = name;
        _streamURL = streamURL;
        _alternateStreamURLs = @[].mutableCopy;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSString *name = [coder decodeObjectForKey:@"name"];
    NSString *streamURL = [coder decodeObjectForKey:@"streamURL"];
    NSNumber *isVOD = [coder decodeObjectForKey:@"isVOD"] ?: @(YES);
    
    NSData *encodedData = [coder decodeObjectForKey:@"alternateStreamURLs"];
    NSMutableArray *alternateStreamURLs = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:encodedData error:nil];
    
    StreamInfo *streamInfo = [self initWithName:name streamURL:streamURL];
    streamInfo.isVOD = isVOD.boolValue;
    streamInfo.alternateStreamURLs = alternateStreamURLs;
    
    return streamInfo;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.streamURL forKey:@"streamURL"];
    [coder encodeObject:@(self.isVOD) forKey:@"isVOD"];
    
    NSData *encodedData = [NSKeyedArchiver archivedDataWithRootObject:self.alternateStreamURLs requiringSecureCoding:YES error:nil];
    [coder encodeObject:encodedData forKey:@"alternateStreamURLs"];
}

- (BOOL)isEqual:(id)object
{
    if (!object)
    {
        return NO;
    }
    
    if (![object isKindOfClass:StreamInfo.class])
    {
        return NO;
    }
    
    StreamInfo *streamInfo = (StreamInfo *)object;
    return [self.name isEqualToString:streamInfo.name] && [streamInfo.streamURL isEqualToString:self.streamURL];
}

@end
