//
//  Thumbnailer.m
//  Grocery Dude
//
//  Created by Gerry on 7/23/16.
//  Copyright © 2016 Tim Roadley. All rights reserved.
//

#import "Thumbnailer.h"
#import "Faulter.h"

@implementation Thumbnailer
#define debug 1

+ (void)createMissingThumbnailsForEntityName:(NSString *)entityName
                  withThumbnailAttributeName:(NSString *)thumbnailAttributeName
                   withPhotoRelationshipName:(NSString *)photoRelationshipName
                      withPhotoAttributeName:(NSString *)phototAttributeName
                         withSortDescriptors:(NSArray *)sortDescriptors
                           withImportContext:(NSManagedObjectContext *)importContext {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    [importContext performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
        request.predicate = [NSPredicate predicateWithFormat:@"%K==nil && %K.%K!=nil", thumbnailAttributeName, photoRelationshipName, phototAttributeName];
        request.sortDescriptors = sortDescriptors;
        request.fetchBatchSize = 15;
        
        NSError *error = nil;
        NSArray *missingThumbnails = [importContext executeFetchRequest:request error:&error];
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
        
        for (NSManagedObject *object in missingThumbnails) {
            NSManagedObject *photoObject = [object valueForKey:photoRelationshipName];
            if (![object valueForKey:thumbnailAttributeName] && [photoObject valueForKey:phototAttributeName]) {
                // Create Thumbnail
                UIImage *photo = [UIImage imageWithData:[photoObject valueForKey:phototAttributeName]];
                CGSize size = CGSizeMake(66, 66);
                UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
                [photo drawInRect:CGRectMake(0, 0, size.width, size.width)];
                UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                [object setValue:UIImagePNGRepresentation(thumbnail) forKey:thumbnailAttributeName];
                
                // Fault photo object out of memory
                [Faulter faultObjectWithID:photoObject.objectID inContext:importContext];
                [Faulter faultObjectWithID:object.objectID inContext:importContext];
                
                // Remove unused variables
                photo = nil;
                thumbnail = nil;
            }
        }
    }];
}

@end