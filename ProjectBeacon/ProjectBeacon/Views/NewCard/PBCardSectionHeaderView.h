//
//  PBCardSectionHeaderView.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/12/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBCardSectionHeaderView : UITableViewHeaderFooterView


@property (weak, nonatomic) IBOutlet UILabel *headerTitle;
@property (weak, nonatomic) IBOutlet UIButton *addButton;

@end
