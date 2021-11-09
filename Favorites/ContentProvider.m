//
//  ContentProvider.m
//  Favorites
//
//  Created by Jeremy Blaker on 7/24/21.
//

#import "ContentProvider.h"

@interface ContentProvider ()

@property (nonatomic, strong) TVTopShelfSectionedContent *content;

@end

@implementation ContentProvider

- (void)loadTopShelfContentWithCompletionHandler:(void (^) (id<TVTopShelfContent> content))completionHandler {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    NSArray *favorites = dict[@"FavoriteShows"];
    NSMutableArray *items = @[].mutableCopy;
    
    for (NSDictionary *favoriteShow in favorites)
    {
        if (![favoriteShow[@"active"] boolValue])
        {
            continue;
        }
        NSString *name = favoriteShow[@"name"];
        NSString *imageURL = favoriteShow[@"imageURL"];
        TVTopShelfSectionedItem *item = [[TVTopShelfSectionedItem alloc] initWithIdentifier:name];
        item.imageShape = TVTopShelfSectionedItemImageShapePoster;
        item.title = name;
        if (imageURL)
        {
            [item setImageURL:[NSURL URLWithString:imageURL] forTraits:TVTopShelfItemImageTraitScreenScale1x];
        }
        NSString *showPath = [name stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
        NSString *urlString = [NSString stringWithFormat:@"zerotv://topshelf?show=%@", showPath];
        NSURL *url = [NSURL URLWithString:urlString];
        item.displayAction = [[TVTopShelfAction alloc] initWithURL:url];
        [items addObject:item];
    }
    
    TVTopShelfItemCollection *collection = [[TVTopShelfItemCollection alloc] initWithItems:items];
    collection.title = @"Favorite Shows";
    
    self.content = [[TVTopShelfSectionedContent alloc] initWithSections:@[collection]];
    
    completionHandler(self.content);
}

@end
