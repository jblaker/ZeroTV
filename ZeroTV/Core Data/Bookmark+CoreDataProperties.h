//
//  Bookmark+CoreDataProperties.h
//  
//
//  Created by Jeremy Blaker on 9/4/23.
//
//

#import "Bookmark+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Bookmark (CoreDataProperties)

+ (NSFetchRequest<Bookmark *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *streamURL;
@property (nullable, nonatomic, assign) BOOL isVOD;
@property (nullable, nonatomic, copy) NSString *searchTerm;
@property (nullable, nonatomic, copy) NSArray *subtitleOptions;
@property (nullable, nonatomic, assign) BOOL didDownloadSubFile;
@property (nullable, nonatomic, copy) NSString *favoriteGroupName;
@property (nullable, nonatomic, copy) NSMutableArray *alternateStreamURLs;

@end

NS_ASSUME_NONNULL_END
