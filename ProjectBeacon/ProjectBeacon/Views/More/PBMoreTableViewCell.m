//
//  PBMoreTableViewCell.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 2/16/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBMoreTableViewCell.h"
#import "Constants.h"


@implementation PBMoreTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setEnabled:(BOOL)enabled {
    if (enabled) {
        self.cellImage.alpha = 1;
        self.cellText.textColor = [UIColor blackColor];
    }
    else {
        self.cellImage.alpha = 0.45;
        self.cellText.textColor = kCellDisabledColor;
    }
    self.cellSwitch.enabled = enabled;

}

@end
