//
//  PBMoreTableViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/5/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBMoreTableViewController : UITableViewController

@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *cells;

- (void)updateBluetoothStatus:(BOOL)status;
- (IBAction)switchWatching:(id)sender;
- (IBAction)switchPublishing:(id)sender;
@end
