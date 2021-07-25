//
//  AppDelegate.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    NSArray *queryParams = [url.query componentsSeparatedByString:@"&"];
    
    NSString *showName;

    for (NSString *param in queryParams)
    {
        if ([param hasPrefix:@"show="])
        {
            showName = [param componentsSeparatedByString:@"="].lastObject;
            break;
        }
    }
    
    showName = [showName stringByRemovingPercentEncoding];
    
    if (showName)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FavoritesDeepLinkNotification" object:nil userInfo:@{@"name":showName}];
        return YES;
    }
    
    return NO;
}

@end
