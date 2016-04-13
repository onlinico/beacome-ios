//
//  PBVCardTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/28/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"


@interface PBVCardTableViewCell : MGSwipeTableCell


@property (weak, nonatomic) IBOutlet UIImageView *vCardImage;
@property (weak, nonatomic) IBOutlet UILabel *vCardFullName;
@property (weak, nonatomic) IBOutlet UILabel *vCardEmail;
@property (weak, nonatomic) IBOutlet UILabel *vCardPhone;

- (void)setEnabled:(BOOL)enabled;

@end
