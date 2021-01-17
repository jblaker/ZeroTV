//
//  StreamInfo.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "StreamInfo.h"

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

@end
