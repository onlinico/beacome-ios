//
//  PBLinkBeaconViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/12/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol PBPassDataDelegate;


@interface PBLinkBeaconViewController : UIViewController


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id <PBPassDataDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *selectedBeacons;

- (IBAction)cancelAction:(id)sender;
- (IBAction)linkAction:(id)sender;
- (IBAction)addAction:(id)sender;

@end
