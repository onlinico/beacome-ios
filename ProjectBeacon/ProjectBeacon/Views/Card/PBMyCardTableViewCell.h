//
//  PBMyCardTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/28/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"


@interface PBMyCardTableViewCell : MGSwipeTableCell


@property (weak, nonatomic) IBOutlet UIImageView *cardImage;
@property (weak, nonatomic) IBOutlet UILabel *cardTitle;
@property (weak, nonatomic) IBOutlet UILabel *cardDescription;
@property (weak, nonatomic) IBOutlet UILabel *cardPermission;
@property (weak, nonatomic) IBOutlet UILabel *linkedBeaconsCount;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;

- (void)setEnabled:(BOOL)enabled;
@end
