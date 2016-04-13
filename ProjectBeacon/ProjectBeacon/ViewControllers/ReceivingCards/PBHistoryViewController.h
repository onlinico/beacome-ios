//
//  PBHistoryViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/24/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBHistoryViewController : UIViewController


@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)showSortView:(id)sender;

@end
