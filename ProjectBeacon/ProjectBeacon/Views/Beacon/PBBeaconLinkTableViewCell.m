//
// Created by Oleksandr Malyarenko on 1/12/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import "PBBeaconLinkTableViewCell.h"


@implementation PBBeaconLinkTableViewCell {

}


- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.selectButton.selected = selected;
    // Configure the view for the selected state
}

@end