//
//  OpenSubtitlesAdapter.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/23/20.
//

#import "OpenSubtitlesAdapter.h"

NSString * const kOpenSubsTVEndpoint = @"https://api.opensubtitles.com/api/v1/subtitles";
NSString * const kAPIKeyKey = @"Api-Key";

@implementation OpenSubtitlesAdapter

+ (NSString *)APIKey
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    return dict[@"OpenSubtitlesAPIKey"];
}

+ (void)subtitleSearch:(NSString *)query completionHandler:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completionHandler
{
    query = [NSString stringWithFormat:@"%@?query=%@", kOpenSubsTVEndpoint, query];
    
    NSURL *url = [NSURL URLWithString:[query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[OpenSubtitlesAdapter APIKey] forHTTPHeaderField:kAPIKeyKey];

    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, error);
            });
        }
        else
        {
            NSError *jsonError;
            NSDictionary *resDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            
            if (jsonError)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(nil, jsonError);
                });
            }
            else
            {
                NSArray *errorsMsgs = resDict[@"errors"];
                
                if (errorsMsgs)
                {
                    NSError *error = [NSError errorWithDomain:@"OpenSubtitlesAdapter" code:0 userInfo:@{
                        NSLocalizedDescriptionKey : errorsMsgs.firstObject ?: @"Unknown Error"
                    }];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(nil, error);
                    });
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(resDict, nil);
                    });
                }
                
            }
            
        }

    }];
    
    [task resume];
}

+ (void)subtitleDownload:(NSDictionary *)subtitle completionHandler:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completionHandler
{
    NSArray *files = subtitle[@"files"];
    NSDictionary *firstFile = files.firstObject;
    NSString *fileId = [NSString stringWithFormat:@"%@", firstFile[@"file_id"]];

    // https://opensubtitles.stoplight.io/docs/opensubtitles-api/open_api.json/paths/~1api~1v1~1download/post
    
    NSDictionary *postBodyParams = @{
        @"file_id" : fileId,
        @"sub_format" : @"webvtt"
    };

    NSURL *url = [NSURL URLWithString:@"https://www.opensubtitles.com/api/v1/download"];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[OpenSubtitlesAdapter APIKey] forHTTPHeaderField:kAPIKeyKey];
    [request setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    
    request.HTTPBody = [OpenSubtitlesAdapter encodeDictionary:postBodyParams];

    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, error);
            });
        }
        else
        {
            NSError *jsonError;
            NSDictionary *resDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            
            if (jsonError)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(nil, error);
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(resDict, nil);
                });
            }
        }

    }];

    [task resume];
}

+ (NSArray *)englishSubtitlesFromSearchResponse:(NSDictionary *)searchResponse
{
    NSArray *results = searchResponse[@"data"];
    NSMutableArray *matchingResults = @[].mutableCopy;
    
    for (NSDictionary *result in results)
    {
        NSDictionary *attributes = result[@"attributes"];
        NSString *type = result[@"type"];
        NSString *lang = attributes[@"language"];
        
        if ([type isEqualToString:@"subtitle"] && [lang isEqualToString:@"en"])
        {
            [matchingResults addObject:attributes];
        }
    }
    
    return matchingResults;
}

+ (NSData *)encodeDictionary:(NSDictionary *)dictionary
{
    NSMutableArray *parts = @[].mutableCopy;
    for (NSString *key in dictionary)
    {
        NSString *encodedValue = [[dictionary objectForKey:key] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
        NSString *encodedKey = [key stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject:part];
    }
    NSString *encodedDictionary = [parts componentsJoinedByString:@"&"];
    return [encodedDictionary dataUsingEncoding:NSUTF8StringEncoding];
}


@end
