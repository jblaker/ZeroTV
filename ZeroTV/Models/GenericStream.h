//
//  GenericStream.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 9/5/23.
//

@protocol GenericStream <NSObject>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *streamURL;
@property (nonatomic, strong) NSArray *subtitleOptions;
@property (nonatomic, assign) BOOL isVOD;
@property (nonatomic, assign) BOOL didDownloadSubFile;
@property (nonatomic, copy) NSString *imdbID;
@property (nonatomic, copy) NSString *favoriteGroupName;
@property (nonatomic, strong) NSMutableArray *alternateStreamURLs;

@end
