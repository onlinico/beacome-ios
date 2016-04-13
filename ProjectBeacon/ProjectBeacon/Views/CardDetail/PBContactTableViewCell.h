//
//  PBContactTableViewCell.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/18/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>


@interface PBContactTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *contactType;
@property (weak, nonatomic) IBOutlet UILabel *contactValue;

@end
