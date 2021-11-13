//
//  EPGChannel.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 11/12/21.
//

#import <Foundation/Foundation.h>

@class EPGProgram;

NS_ASSUME_NONNULL_BEGIN

@interface EPGChannel : NSObject

@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, copy) NSString *channelName;
@property (nonatomic, strong) NSMutableArray<EPGProgram *> *programs;

@end

NS_ASSUME_NONNULL_END
