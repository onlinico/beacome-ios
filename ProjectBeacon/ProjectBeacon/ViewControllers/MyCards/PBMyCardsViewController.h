//
//  PBMyCardsViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/28/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol PBPassDataDelegate;


@interface PBMyCardsViewController : UIViewController


@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, assign) BOOL selectionMode;
@property (nonatomic, strong) NSMutableArray *selectedCards;
@property (nonatomic, weak) id <PBPassDataDelegate> delegate;

- (IBAction)showSortView:(id)sender;

@end
