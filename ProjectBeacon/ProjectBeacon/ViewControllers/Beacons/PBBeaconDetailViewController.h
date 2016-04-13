//
//  PBBeaconDetailViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/8/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBBeaconDetailViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIToolbar *actionsToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *linkOnButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *linkOffButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, assign) BOOL deviceAsBeacon;
@property (nonatomic, strong) id beacon;

- (IBAction)linkOffAction:(id)sender;
- (IBAction)linkOnAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
- (IBAction)saveAction:(id)sender;
@end
