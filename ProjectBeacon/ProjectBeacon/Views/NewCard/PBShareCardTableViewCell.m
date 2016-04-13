//
//  PBShareCardTableViewCell.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/13/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBShareCardTableViewCell.h"


@implementation PBShareCardTableViewCell


- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)setEnabled:(BOOL)enabled {
    self.fullName.enabled = enabled;
    self.permission.enabled = enabled;
    self.email.enabled = enabled;
    self.userImage.alpha = (CGFloat) (enabled ? 1.0 : 0.45);

}

@end
