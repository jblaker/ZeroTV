//
//  EpisodeManager.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 12/26/20.
//

#import "EpisodeManager.h"
#import "StreamInfo.h"
#import "CoreDataManager.h"
#import "Progress+CoreDataClass.h"

float const kPlaybackCompletionTreshold = 0.75;

NSString * const kProgressEntityName = @"Progress";

@implementation EpisodeManager

+ (void)episodeDidComplete:(id<GenericStream>)episode withPlaybackPosition:(float)playbackPosition
{
    if (playbackPosition > kPlaybackCompletionTreshold)
    {
        [EpisodeManager markAsWatched:episode];
    }
}

+ (void)saveProgressForEpisode:(id<GenericStream>)episode withPlaybackTime:(int)playbackTime
{
    if (!episode.isVOD)
    {
        return;
    }

    NSManagedObjectContext *context = CoreDataManager.sharedManager.persistentContainer.viewContext;
    Progress *progress = [EpisodeManager progressFromEpisode:episode];
    
    if (!progress)
    {
        NSEntityDescription *newEntity = [NSEntityDescription entityForName:kProgressEntityName inManagedObjectContext:context];
        progress = (Progress *)[[NSManagedObject alloc] initWithEntity:newEntity insertIntoManagedObjectContext:context];
        progress.name = episode.name;
    }
    
    progress.progress = playbackTime;
    
    NSError *error;
    [context save:&error];
    
    NSLog(@"Did update episode progress : %@", !error ? @"YES" : @"NO");
}

+ (void)markAsWatched:(id<GenericStream>)episode
{
    NSManagedObjectContext *context = CoreDataManager.sharedManager.persistentContainer.viewContext;
    Progress *progress = [EpisodeManager progressFromEpisode:episode];
    
    if (!progress)
    {
        NSEntityDescription *newEntity = [NSEntityDescription entityForName:kProgressEntityName inManagedObjectContext:context];
        progress = (Progress *)[[NSManagedObject alloc] initWithEntity:newEntity insertIntoManagedObjectContext:context];
        progress.name = episode.name;
    }

    progress.completed = YES;
    
    NSError *error;
    [context save:&error];
    
    NSLog(@"Did update watched eps : %@", !error ? @"YES" : @"NO");
}

+ (void)markAsUnwatched:(id<GenericStream>)episode
{
    NSManagedObjectContext *context = CoreDataManager.sharedManager.persistentContainer.viewContext;
    
    Progress *progress = [EpisodeManager progressFromEpisode:episode];
    if (progress)
    {
        [context deleteObject:progress];
    }
    
    NSError *error;
    [context save:&error];
    
    NSLog(@"Did remove stream progress: %@", !error ? @"YES" : @"NO");
}

+ (BOOL)episodeWasWatched:(id<GenericStream>)episode
{
    Progress *progress = [EpisodeManager progressFromEpisode:episode];
    return progress.completed;
}

+ (Progress *)progressFromEpisode:(id<GenericStream>)episode
{
    NSManagedObjectContext *context = CoreDataManager.sharedManager.persistentContainer.viewContext;
    NSFetchRequest *request = Progress.fetchRequest;
    
    NSError *error;
    NSArray *epProgresses = [context executeFetchRequest:request error:&error];
    
    for (Progress *progress in epProgresses)
    {
        if ([progress.name isEqualToString:episode.name])
        {
            return progress;
        }
    }
    
    return nil;
}

+ (int)progressForEpisode:(id<GenericStream>)episode
{
    Progress *progress = [EpisodeManager progressFromEpisode:episode];
    return progress.progress;
}

@end
