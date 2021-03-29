//
//  M3U8Manager.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/23/20.
//

#import "M3U8Manager.h"
#import "StreamingGroup.h"
#import "StreamInfo.h"

static NSString * const kGroupPrefix = @"#EXTGRP:";
static NSString * const kLineInfoPrefix = @"#EXTINF:";

@implementation M3U8Manager

+ (void)fetchManifest:(void (^)(NSData * _Nullable, NSError * _Nullable))completionHandler
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    NSURL *manifestURL = [NSURL URLWithString:dict[@"ManifestURL"]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:manifestURL];

    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, error);
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(data, nil);
            });
        }

    }];

    [task resume];
}

+ (NSDictionary *)parseManifest:(NSData *)manifestData
{
    NSString *manifest = [[NSString alloc] initWithData:manifestData encoding:NSUTF8StringEncoding];
    NSArray *lines = [manifest componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableDictionary *groups = @{}.mutableCopy;

    StreamingGroup *currentGroup;
    NSString *streamName;
    
    for (NSString *line in lines)
    {
        // Group name line
//        if ([line hasPrefix:kGroupPrefix])
//        {
//            NSArray *parts = [line componentsSeparatedByString:kGroupPrefix];
//            NSString *groupName = parts.lastObject;
//
//            StreamingGroup *group = groups[groupName];
//            if (!group)
//            {
//                group = [[StreamingGroup alloc] initWithName:groupName];
//                groups[groupName] = group;
//            }
//
//            currentGroup = group;
//        }
        
        if ([line hasPrefix:kLineInfoPrefix])
        {
            // Alternate group detection
            {
                NSError *regexError;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"group-title=\"(.*?)\"" options:NSRegularExpressionCaseInsensitive error:&regexError];
                NSArray *matches = [regex matchesInString:line options:0 range:NSMakeRange(0, line.length)];
                NSTextCheckingResult *firstMatch = matches.firstObject;
                NSString *groupName = [line substringWithRange:[firstMatch rangeAtIndex:1]];
                
                StreamingGroup *group = groups[groupName];
                if (!group)
                {
                    group = [[StreamingGroup alloc] initWithName:groupName];
                    groups[groupName] = group;
                }
                
                currentGroup = group;
            }
            
            NSArray *parts = [line componentsSeparatedByString:@","];
            streamName = parts.lastObject;
        }
        
        
        if ([line hasPrefix:@"https:"] || [line hasPrefix:@"http:"])
        {
            StreamInfo *streamInfo = [[StreamInfo alloc] initWithName:streamName streamURL:line];
            if ([currentGroup.name isEqualToString:@"TV VOD"] || [currentGroup.name isEqualToString:@"Movie VOD"])
            {
                streamInfo.isVOD = YES;
            }
            [currentGroup.streams addObject:streamInfo];
        }
    }
    
    return groups;
}

@end
