//
//  PBNewCardViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/12/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@class PBCard;
@protocol PBPassDataDelegate;


@interface PBNewCardViewController : UIViewController


@property (nonatomic, weak) id <PBPassDataDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *actionsToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *linkOffButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *linkOnButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareChangingButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *vCardButton;

@property (nonatomic, strong) PBCard *card;

- (IBAction)cancelAction:(id)sender;
- (IBAction)saveAction:(id)sender;
- (IBAction)linkOffAction:(id)sender;
- (IBAction)linkOnAction:(id)sender;
- (IBAction)shareChangeAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
- (IBAction)vCardChangeAction:(id)sender;
@end
