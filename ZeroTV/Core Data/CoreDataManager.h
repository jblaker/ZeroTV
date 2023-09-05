//
//  CoreDataManager.h
//  ZeroTV
//
//  Created by Jeremy Blaker on 9/4/23.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataManager : NSObject

+ (instancetype)sharedManager;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;

@end

NS_ASSUME_NONNULL_END
