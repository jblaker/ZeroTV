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
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSString *name = [coder decodeObjectForKey:@"name"];
    NSString *streamURL = [coder decodeObjectForKey:@"streamURL"];
    return [self initWithName:name streamURL:streamURL];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.streamURL forKey:@"streamURL"];
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
