//
//  PBMoreTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 2/16/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBMoreTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UILabel *cellText;
@property (weak, nonatomic) IBOutlet UISwitch *cellSwitch;

- (void)setEnabled:(BOOL)enabled;
@end
