//
//  PBCardContactTableViewCell.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/13/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBCardContactTableViewCell.h"


@implementation PBCardContactTableViewCell


- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)setEnabled:(BOOL)enabled {
    self.contact.enabled = enabled;
    self.contactType.enabled = enabled;
    self.removeContactButton.enabled = enabled;

}

@end
