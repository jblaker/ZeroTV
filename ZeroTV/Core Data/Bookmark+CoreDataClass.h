//
//  Bookmark+CoreDataClass.h
//  
//
//  Created by Jeremy Blaker on 9/4/23.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GenericStream.h"

NS_ASSUME_NONNULL_BEGIN

@interface Bookmark : NSManagedObject<GenericStream>

@end

NS_ASSUME_NONNULL_END

#import "Bookmark+CoreDataProperties.h"
