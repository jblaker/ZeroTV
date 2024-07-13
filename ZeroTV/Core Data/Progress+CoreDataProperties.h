//
//  Progress+CoreDataProperties.h
//  
//
//  Created by Jeremy Blaker on 9/4/23.
//
//

#import "Progress+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Progress (CoreDataProperties)

+ (NSFetchRequest<Progress *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) int progress;
@property (nonatomic) BOOL completed;

@end

NS_ASSUME_NONNULL_END
