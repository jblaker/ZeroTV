//
//  StreamInfo.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import <Foundation/Foundation.h>
#import "GenericStream.h"

NS_ASSUME_NONNULL_BEGIN

@interface StreamInfo : NSObject<GenericStream>

- (instancetype)initWithName:(NSString *)name streamURL:(NSString *)streamURL NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *streamURL;
@property (nonatomic, assign) BOOL didDownloadSubFile;
@property (nonatomic, assign) BOOL isVOD;
@property (nonatomic, strong) NSArray *subtitleOptions;
@property (nonatomic, copy) NSString *imdbID;
@property (nonatomic, copy) NSString *favoriteGroupName;
@property (nonatomic, strong) NSMutableArray *alternateStreamURLs;

@end

NS_ASSUME_NONNULL_END
