//
//  EPGManager.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 11/12/21.
//

#import <Foundation/Foundation.h>

extern const NSNotificationName _Nonnull kZeroTVEPAMangerReadyNotification;

NS_ASSUME_NONNULL_BEGIN

@interface EPGManager : NSObject

+ (void)fetchEPGData:(BOOL)useCached;
+ (NSArray * _Nullable)programsForChannelName:(NSString *)channelName;

@end

NS_ASSUME_NONNULL_END
