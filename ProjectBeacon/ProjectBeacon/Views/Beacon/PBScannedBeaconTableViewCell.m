//
//  PBScannedBeaconTableViewCell.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/14/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBScannedBeaconTableViewCell.h"


@implementation PBScannedBeaconTableViewCell


- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.selectButton.selected = selected;
    // Configure the view for the selected state
}

@end
