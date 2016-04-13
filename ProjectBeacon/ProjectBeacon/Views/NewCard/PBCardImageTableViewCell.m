//
//  PBCardImageTableViewCell.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/13/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBCardImageTableViewCell.h"


@implementation PBCardImageTableViewCell


- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)setEnabled:(BOOL)enabled {
    self.chooseImageButton.enabled = enabled;
    self.cardImage.alpha = (CGFloat) (enabled ? 1.0 : 0.45);
}

@end
