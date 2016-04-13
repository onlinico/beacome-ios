//
//  PBAddVCardViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/14/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol PBPassDataDelegate;
@class PBVCard;


@interface PBAddVCardViewController : UIViewController


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;

@property (nonatomic, assign) NSInteger index;
@property (weak, nonatomic) id <PBPassDataDelegate> delegate;
@property (nonatomic, strong) PBVCard *vCard;

- (IBAction)cancelAction:(id)sender;
- (IBAction)addAction:(id)sender;

@end
