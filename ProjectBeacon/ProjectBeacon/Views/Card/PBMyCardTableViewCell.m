//
//  PBMyCardTableViewCell.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/28/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import "PBMyCardTableViewCell.h"
#import "Constants.h"


@implementation PBMyCardTableViewCell


- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.selectButton.selected = selected;
    // Configure the view for the selected state
}


- (void)setEnabled:(BOOL)enabled {
    if (enabled) {
        self.cardImage.alpha = 1;
        self.cardTitle.textColor = [UIColor blackColor];
        self.cardDescription.textColor = [UIColor blackColor];
        self.cardPermission.textColor = [UIColor blackColor];
        self.linkedBeaconsCount.textColor = [UIColor blackColor];
    }
    else {
        self.cardImage.alpha = 0.45;
        self.cardTitle.textColor = kCellDisabledColor;
        self.cardDescription.textColor = kCellDisabledColor;
        self.cardPermission.textColor = kCellDisabledColor;
        self.linkedBeaconsCount.textColor = kCellDisabledColor;
    }

}

@end
