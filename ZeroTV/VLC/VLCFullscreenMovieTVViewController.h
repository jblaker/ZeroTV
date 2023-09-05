//
//  VLCFullscreenMovieTVViewController.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/21/20.
//

#import <Foundation/Foundation.h>
#import "VLCPlaybackService.h"

@protocol GenericStream;

NS_ASSUME_NONNULL_BEGIN

@interface ProgressBar : UIView

@end

@interface VLCFullscreenMovieTVViewController : UIViewController <VLCPlaybackServiceDelegate>

@property (nonatomic, strong) NSObject<GenericStream> *selectedStream;

@end

NS_ASSUME_NONNULL_END
