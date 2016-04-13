//
//  PBCardContactTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/13/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBCardContactTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UIButton *contactType;
@property (weak, nonatomic) IBOutlet UITextField *contact;
@property (weak, nonatomic) IBOutlet UIButton *removeContactButton;


- (void)setEnabled:(BOOL)enabled;

@end
