//
//  PBHistoryTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/24/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"


@interface PBHistoryTableViewCell : MGSwipeTableCell


@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;
@property (weak, nonatomic) IBOutlet UILabel *cellDetail;
@property (weak, nonatomic) IBOutlet UILabel *cellTime;
@property (weak, nonatomic) IBOutlet UIView *cellContentView;
@property (weak, nonatomic) IBOutlet UIImageView *favoriteIcon;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *cellConstraints;
@end
