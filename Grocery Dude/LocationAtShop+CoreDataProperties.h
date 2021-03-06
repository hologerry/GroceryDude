//
//  LocationAtShop+CoreDataProperties.h
//  Grocery Dude
//
//  Created by Gerry on 7/22/16.
//  Copyright © 2016 Tim Roadley. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LocationAtShop.h"

NS_ASSUME_NONNULL_BEGIN

@interface LocationAtShop (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *aisle;
@property (nullable, nonatomic, retain) NSSet<Item *> *items;

@end

@interface LocationAtShop (CoreDataGeneratedAccessors)

- (void)addItemsObject:(Item *)value;
- (void)removeItemsObject:(Item *)value;
- (void)addItems:(NSSet<Item *> *)values;
- (void)removeItems:(NSSet<Item *> *)values;

@end

NS_ASSUME_NONNULL_END
