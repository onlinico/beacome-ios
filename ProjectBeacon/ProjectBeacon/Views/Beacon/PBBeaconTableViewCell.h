//
//  PBBeaconTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/8/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBBeaconTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *beaconUid;
@property (weak, nonatomic) IBOutlet UILabel *linkedCardsCount;


- (void)setEnabled:(BOOL)enabled;

@end
