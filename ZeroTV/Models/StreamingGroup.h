//
//  StreamingGroup.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import <Foundation/Foundation.h>

@class StreamInfo;

NS_ASSUME_NONNULL_BEGIN

@interface StreamingGroup : NSObject

- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;
- (void)filterDuplicates:(void (^)(void))completion;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSMutableArray<StreamInfo *> *streams;
@property (nonatomic, assign) BOOL isFavorite;

@end

NS_ASSUME_NONNULL_END
