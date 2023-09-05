//
//  Progress+CoreDataProperties.m
//  
//
//  Created by Jeremy Blaker on 9/4/23.
//
//

#import "Progress+CoreDataProperties.h"

@implementation Progress (CoreDataProperties)

+ (NSFetchRequest<Progress *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Progress"];
}

@dynamic name;
@dynamic progress;

@end
