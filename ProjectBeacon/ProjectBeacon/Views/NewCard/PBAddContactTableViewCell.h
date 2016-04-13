//
//  PBAddContactTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/13/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBAddContactTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *contactTypePlaceholder;
@property (weak, nonatomic) IBOutlet UIButton *addContactButton;


- (void)setEnabled:(BOOL)enabled;

@end
