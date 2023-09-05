//
//  DownloadUploadManager.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/23/20.
//

#import "DownloadUploadManager.h"

@implementation DownloadUploadManager

+ (void)fetchSubtitleFileData:(NSURL *)url completionHandler:(void (^)(NSData * _Nullable, NSError * _Nullable))completionHandler
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
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
