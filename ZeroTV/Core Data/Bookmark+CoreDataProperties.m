//
//  Bookmark+CoreDataProperties.m
//  
//
//  Created by Jeremy Blaker on 9/4/23.
//
//

#import "Bookmark+CoreDataProperties.h"

@implementation Bookmark (CoreDataProperties)

+ (NSFetchRequest<Bookmark *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Bookmark"];
}

@dynamic name;
@dynamic streamURL;
@dynamic isVOD;
@dynamic searchTerm;
@dynamic subtitleOptions;
@dynamic didDownloadSubFile;
@dynamic favoriteGroupName;
@dynamic alternateStreamURLs;

@end
