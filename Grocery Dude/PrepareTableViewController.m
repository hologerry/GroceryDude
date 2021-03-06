//
//  PrepareTableViewController.m
//  Grocery Dude
//
//  Created by Gerry on 7/19/16.
//  Copyright © 2016 Tim Roadley. All rights reserved.
//

#import "PrepareTableViewController.h"
#import "CoreDataHelper.h"
#import "Item.h"
#import "Unit.h"
#import "AppDelegate.h"
#import "ItemViewController.h"
#import "Thumbnailer.h"

@interface PrepareTableViewController ()

@end

@implementation PrepareTableViewController

#define debug 1

#pragma mark - DATA
- (void)configureFetch {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Item"];
    
    request.sortDescriptors = [NSArray arrayWithObjects:
                               [NSSortDescriptor sortDescriptorWithKey:@"locationAtHome.storeIn"
                                                             ascending:YES],
                               [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                             ascending:YES],
                               nil];
    [request setFetchBatchSize:15];
    self.frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                   managedObjectContext:cdh.context
                                                     sectionNameKeyPath:@"locationAtHome.storeIn"
                                                              cacheName:nil];
    self.frc.delegate = self;
}

#pragma mark - VIEW
- (void)viewDidLoad {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    [super viewDidLoad];
    [self configureFetch];
    [self performFetch];
    self.clearConfirmActionSheet.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(performFetch)
                                                 name:@"SomethingChanged"
                                               object:nil];
    [self configureSearch];
}

- (void)viewDidAppear:(BOOL)animated {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    [super viewDidAppear:animated];
    
    // Create missing thumbnails
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    NSArray *sortDescriptors =
    [NSArray arrayWithObjects:
     [NSSortDescriptor sortDescriptorWithKey:@"locationAtHome.storeIn"
                                   ascending:YES],
     [NSSortDescriptor sortDescriptorWithKey:@"name"
                                   ascending:YES],
     nil];
    [Thumbnailer createMissingThumbnailsForEntityName:@"Item"
                           withThumbnailAttributeName:@"thumbnail"
                            withPhotoRelationshipName:@"photo"
                               withPhotoAttributeName:@"data"
                                  withSortDescriptors:sortDescriptors
                                    withImportContext:cdh.importContext];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    static NSString *cellIdentifier = @"Item Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:cellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    Item *item = [[self frcFromTV:tableView] objectAtIndexPath:indexPath];
    
    NSMutableString *title = [NSMutableString stringWithFormat:@"%@%@ %@",
                              item.quantity, item.unit.name, item.name];
    [title replaceOccurrencesOfString:@"(null)"
                           withString:@""
                              options:0
                                range:NSMakeRange(0, [title length])];
    cell.textLabel.text = title;
    
    // make selected items orange
    if ([item.listed boolValue]) {
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:18]];
        [cell.textLabel setTextColor:[UIColor orangeColor]];
    } else {
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:16]];
        [cell.textLabel setTextColor:[UIColor grayColor]];
    }
    cell.imageView.image = [UIImage imageWithData:item.thumbnail];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSFetchedResultsController *frc = [self frcFromTV:tableView];
        Item *deleteTarget = [self.frc objectAtIndexPath:indexPath];
        [frc.managedObjectContext deleteObject:deleteTarget];
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationFade];
    }
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    [cdh backgroundSaveContext];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    NSFetchedResultsController *frc = [self frcFromTV:tableView];
    NSManagedObjectID *itemid = [[frc objectAtIndexPath:indexPath] objectID];
    Item *item = (Item*)[frc.managedObjectContext existingObjectWithID:itemid error:nil];
    
    if ([item.listed boolValue]) {
        item.listed = [NSNumber numberWithBool:NO];
    } else {
        item.listed = [NSNumber numberWithBool:YES];
        item.colletced = [NSNumber numberWithBool:NO];
    }
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - INTERACTION
- (IBAction)clear:(id)sender {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    NSFetchRequest *request = [cdh.model fetchRequestTemplateForName:@"ShoppingList"];
    NSArray *shoppingList = [cdh.context executeFetchRequest:request error:nil];
    
    if (shoppingList.count > 0) {
        self.clearConfirmActionSheet = [[UIActionSheet alloc] initWithTitle:@"Clear Entire Shopping List?"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                     destructiveButtonTitle:@"Clear"
                                                          otherButtonTitles:nil, nil];
        [self.clearConfirmActionSheet showFromTabBar:self.navigationController.tabBarController.tabBar];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nothing to Clear"
                                                        message:@"Add items to the Shop tab by tapping them on the Prepare tab. Remove all items from the Shop by cliking Clear on the Prepare tab"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    shoppingList = nil;
    
    [cdh backgroundSaveContext];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.clearConfirmActionSheet) {
        if (buttonIndex == [actionSheet destructiveButtonIndex]) {
            [self performSelector:@selector(clearList)];
        } else if (buttonIndex == [actionSheet cancelButtonIndex]) {
            [actionSheet dismissWithClickedButtonIndex:[actionSheet cancelButtonIndex] animated:YES];
        }
    }
}

- (void)clearList {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
    NSFetchRequest *request = [cdh.model fetchRequestTemplateForName:@"ShoppingList"];
    NSArray *shoppingList = [cdh.context executeFetchRequest:request error:nil];
    
    for (Item *item in shoppingList) {
        item.listed = [NSNumber numberWithBool:NO];
    }
    [cdh backgroundSaveContext];
}

#pragma mark - SEGUE
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    ItemViewController *itemViewController = segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"Add Item Segue"]) {
        CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
        Item *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"Item"
                                                      inManagedObjectContext:cdh.context];
        NSError *error = nil;
        if (![cdh.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:newItem]
                                                 error:&error]) {
            NSLog(@"Couldn't obtain a permanent ID for object %@", error);
        }
        itemViewController.selectedItemID = newItem.objectID;
    } else {
        NSLog(@"Unidentified Segue Attempted!");
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    ItemViewController *itemViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ItemViewController"];
    itemViewController.selectedItemID = [[[self frcFromTV:tableView] objectAtIndexPath:indexPath] objectID];
    [self.navigationController pushViewController:itemViewController animated:YES];
}

#pragma mark - SEARCH
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    if (debug == 1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if (searchString.length > 0) {
        NSLog(@"--> Searching for '%@'", searchString);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchString];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                    [NSSortDescriptor sortDescriptorWithKey:@"locationAtHome.storeIn" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil];
        CoreDataHelper *cdh = [(AppDelegate *)[[UIApplication sharedApplication] delegate] cdh];
        [self reloadSearchFRCForPredicate:predicate
                               withEntity:@"Item"
                                inContext:cdh.context
                      withSortDescriptors:sortDescriptors
                   withSectionNameKeyPath:@"locationAtHome.storeIn"];
    } else {
        return NO;
    }
    return YES;
}
@end






