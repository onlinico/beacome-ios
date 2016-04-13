//
//  PBCardTextTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/13/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBCardTextTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UITextField *cardText;

- (void)setEnabled:(BOOL)enabled;

@end
