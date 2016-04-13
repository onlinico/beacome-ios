//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBMainViewController.h"
#import "PBApplicationFacade.h"
#import "AppDelegate.h"


@interface PBMainViewController () <UITabBarControllerDelegate>
@end


@implementation PBMainViewController {

}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    if ([[PBApplicationFacade sharedManager] isAnonymus]) {
        [self.tabBar.items[3] setEnabled:NO];
    }
    if(((AppDelegate *)[UIApplication sharedApplication].delegate).needsToProcessURLSchemeRequest){
        [((AppDelegate *) [UIApplication sharedApplication].delegate) processURLSchemeRequest];
    }
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    return [super viewControllerForUnwindSegueAction:action fromViewController:fromViewController withSender:sender];
}


- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([[PBApplicationFacade sharedManager] isAnonymus]) {
        return tabBarController.selectedIndex != 3;
    }
    else {
        return YES;
    }
}

@end