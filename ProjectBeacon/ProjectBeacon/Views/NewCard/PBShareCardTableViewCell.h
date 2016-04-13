//
//  PBShareCardTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/13/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBShareCardTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UILabel *fullName;
@property (weak, nonatomic) IBOutlet UILabel *email;
@property (weak, nonatomic) IBOutlet UILabel *permission;

- (void)setEnabled:(BOOL)enabled;

@end
