//
//  DownloadUploadManager.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/23/20.
//

#import "DownloadUploadManager.h"

@implementation DownloadUploadManager

+ (void)fetchSubtitleFileData:(NSDictionary *)dictionary completionHandler:(void (^)(NSData * _Nullable, NSError * _Nullable))completionHandler
{
    NSString *downloadURL = dictionary[@"link"];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:downloadURL]];

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

@end
