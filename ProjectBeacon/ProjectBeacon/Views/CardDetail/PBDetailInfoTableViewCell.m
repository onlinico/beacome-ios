//
//  PBDetailInfoTableViewCell.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/18/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBDetailInfoTableViewCell.h"
#import "PBLabel.h"


@implementation PBDetailInfoTableViewCell


- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)layoutSubviews {
    [super layoutSubviews];

    [self.cardDetail setNeedsLayout];
    [self.cardDetail layoutIfNeeded];
}

@end
