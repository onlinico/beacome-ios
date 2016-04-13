//
// Created by Oleksandr Malyarenko on 1/12/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//


#import <UIKit/UIKit.h>


@interface PBBeaconLinkTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *beaconUid;
@property (weak, nonatomic) IBOutlet UILabel *linkedCardsCount;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;

@end