//
//  PBCardImageTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/13/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBCardImageTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UIImageView *cardImage;
@property (weak, nonatomic) IBOutlet UIButton *chooseImageButton;

- (void)setEnabled:(BOOL)enabled;

@end
