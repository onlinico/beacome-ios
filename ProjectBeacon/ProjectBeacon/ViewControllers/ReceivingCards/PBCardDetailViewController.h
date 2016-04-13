//
//  PBCardDetailViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/24/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@class PBCard;


@interface PBCardDetailViewController : UIViewController


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *favoriteButton;

@property (nonatomic, strong) PBCard *card;

- (IBAction)favoriteAction:(id)sender;

@end
