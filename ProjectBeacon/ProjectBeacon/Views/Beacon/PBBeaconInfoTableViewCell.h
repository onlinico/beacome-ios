//
//  PBBeaconInfoTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/25/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBBeaconInfoTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoValue;

@end
