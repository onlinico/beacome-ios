//
// Created by Oleksandr Malyarenko on 12/28/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBPageContentViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *pageDescription;
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSString *titleString;
@property (nonatomic, strong) NSString *descriptionString;

@end