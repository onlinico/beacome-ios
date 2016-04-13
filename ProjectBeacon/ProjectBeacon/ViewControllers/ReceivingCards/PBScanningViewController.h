//
//  PBScanningViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/23/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBScanningViewController : UIViewController


@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISwitch *watchingSwitch;

- (IBAction)showSortView:(id)sender;
- (IBAction)switchWatchingMode:(id)sender;

@end
