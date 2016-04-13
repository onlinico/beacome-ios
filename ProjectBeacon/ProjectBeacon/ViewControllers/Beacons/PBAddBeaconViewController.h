//
//  PBAddBeaconViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/14/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol PBPassDataDelegate;


@interface PBAddBeaconViewController : UIViewController


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *uuidTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, weak) id <PBPassDataDelegate> delegate;

- (IBAction)selectBeaconSource:(id)sender;
- (IBAction)addAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
