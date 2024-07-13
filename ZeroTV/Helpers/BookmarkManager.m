//
//  BookmarkManager.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 3/12/22.
//

#import "BookmarkManager.h"
#import "StreamInfo.h"
#import "CoreDataManager.h"
#import "Bookmark+CoreDataClass.h"

NSString * const kBookmarkEntityName = @"Bookmark";

@implementation BookmarkManager

+ (NSArray<NSManagedObject *> *)bookmarks
{
    NSManagedObjectContext *context = CoreDataManager.sharedManager.persistentContainer.viewContext;
    NSFetchRequest *request = Bookmark.fetchRequest;
    
    NSError *error;
    NSArray *bookmarks = [context executeFetchRequest:request error:&error];
    
    if (error)
    {
        NSLog(@"Error fetching bookmarks: %@", error.localizedDescription);
        return nil;
    }

    return bookmarks;
}

+ (void)addBookmarkForStream:(id<GenericStream>)stream
{
    NSManagedObjectContext *context = CoreDataManager.sharedManager.persistentContainer.viewContext;
    NSEntityDescription *newEntity = [NSEntityDescription entityForName:kBookmarkEntityName inManagedObjectContext:context];
    Bookmark *newBookmark = (Bookmark *)[[NSManagedObject alloc] initWithEntity:newEntity insertIntoManagedObjectContext:context];
    
    newBookmark.name = stream.name;
    newBookmark.streamURL = stream.streamURL;
    newBookmark.isVOD = stream.isVOD;
    newBookmark.alternateStreamURLs = stream.alternateStreamURLs;
    
    NSError *error;
    [context save:&error];
    
    NSLog(@"Did update bookmarks : %@", !error ? @"YES" : @"NO");
}

+ (void)removeBookmarkForStream:(id<GenericStream>)stream
{
    NSManagedObjectContext *context = CoreDataManager.sharedManager.persistentContainer.viewContext;
    Bookmark *bookmark = [BookmarkManager bookmarkForStream:stream];
    
    [context deleteObject:bookmark];

    NSError *error;
    [context save:&error];
    
    NSLog(@"Did update bookmarks : %@", !error ? @"YES" : @"NO");
}

+ (BOOL)streamIsBookmarked:(id<GenericStream> )stream
{
    NSManagedObject *bookmark = [BookmarkManager bookmarkForStream:stream];
    if (bookmark)
    {
        return YES;
    }
    return NO;
}

+ (Bookmark *)bookmarkForStream:(id<GenericStream>)streamInfo
{
    NSManagedObjectContext *context = CoreDataManager.sharedManager.persistentContainer.viewContext;
    NSFetchRequest *request = Bookmark.fetchRequest;
    request.predicate = [NSPredicate predicateWithFormat:@"name == %@", streamInfo.name];
    
    NSError *error;
    NSArray *bookmarks = [context executeFetchRequest:request error:&error];
    
    if (error)
    {
        NSLog(@"Error fetching bookmark: %@", error.localizedDescription);
        return nil;
    }
    
    return bookmarks.firstObject;
}

@end
