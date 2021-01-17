//
//  StreamingGroup.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "StreamingGroup.h"

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

@end
