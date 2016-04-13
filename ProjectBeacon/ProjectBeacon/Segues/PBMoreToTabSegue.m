//
//  PBMoreToTabSegue.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/5/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBMoreToTabSegue.h"


@implementation PBMoreToTabSegue


- (void)perform {
    UITabBarController *destinationViewController = self.destinationViewController;
    [destinationViewController setSelectedIndex:self.index];
    [[UIApplication sharedApplication].keyWindow setRootViewController:destinationViewController];
}

@end
