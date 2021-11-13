//
//  EPGChannel.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 11/12/21.
//

#import "EPGChannel.h"

@implementation EPGChannel

- (instancetype)init
{
    if (self = [super init])
    {
        _programs = @[].mutableCopy;
    }
    return self;
}

@end
