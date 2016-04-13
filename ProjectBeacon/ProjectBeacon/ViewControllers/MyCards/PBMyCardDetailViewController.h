//
//  PBMyCardDetailViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/12/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@class PBCard;


@interface PBMyCardDetailViewController : UIViewController


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) PBCard *card;

@end
