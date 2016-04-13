//
// Created by Oleksandr Malyarenko on 12/28/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBPageContentViewController.h"
#import "PBSettingsManager.h"


@implementation PBPageContentViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.backgroundImage.image = [UIImage imageNamed:self.imageName];
    self.pageControl.currentPage = self.index;
    self.pageTitle.text = self.titleString;
    self.pageDescription.text = self.descriptionString;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SignInSegue"]) {
        [[PBSettingsManager sharedManager] setFirstLaunch:NO];
    }
}

@end