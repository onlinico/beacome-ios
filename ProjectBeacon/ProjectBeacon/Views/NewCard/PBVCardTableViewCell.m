//
//  PBVCardTableViewCell.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/28/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import "PBVCardTableViewCell.h"


@implementation PBVCardTableViewCell


- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)setEnabled:(BOOL)enabled {
    self.vCardFullName.enabled = enabled;
    self.vCardPhone.enabled = enabled;
    self.vCardEmail.enabled = enabled;
    self.vCardImage.alpha = (CGFloat) (enabled ? 1.0 : 0.45);

}

@end
