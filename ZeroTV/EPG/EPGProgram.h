//
//  EPGProgram.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 11/12/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EPGProgram : NSObject

@property (nonatomic, copy) NSString *programName;
@property (nonatomic, copy) NSString *programDescription;
@property (nonatomic, assign) NSTimeInterval startTimestamp;
@property (nonatomic, assign) NSTimeInterval stopTimestamp;

@end

NS_ASSUME_NONNULL_END
