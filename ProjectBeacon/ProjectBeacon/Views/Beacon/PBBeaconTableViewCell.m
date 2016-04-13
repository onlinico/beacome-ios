//
//  PBBeaconTableViewCell.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/8/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBBeaconTableViewCell.h"
#import "Constants.h"


@implementation PBBeaconTableViewCell


- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)setEnabled:(BOOL)enabled {
    if (enabled) {
        self.beaconUid.textColor = [UIColor blackColor];
        self.linkedCardsCount.textColor = [UIColor blackColor];
    }
    else {
        self.beaconUid.textColor = kCellDisabledColor;
        self.linkedCardsCount.textColor = kCellDisabledColor;
    }

}

@end
