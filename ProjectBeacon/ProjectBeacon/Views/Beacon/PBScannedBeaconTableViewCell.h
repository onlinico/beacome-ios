//
//  PBScannedBeaconTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/14/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBScannedBeaconTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *beaconUUID;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;

@end
