//
//  PBIntroViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/28/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import "PBIntroViewController.h"
#import "PBPageContentViewController.h"


@interface PBIntroViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>


@property (nonatomic, strong) NSArray *backgroundImages;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *descriptions;

@end


@implementation PBIntroViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    self.backgroundImages = @[@"page1", @"page2", @"page3"];
    self.titles = @[NSLocalizedString(@"iBeacon", @"iBeacon"), NSLocalizedString(@"Explore", @"Explore"), NSLocalizedString(@"Share", @"Share")];
    self.descriptions = @[NSLocalizedString(@"It's a tiny computer that broadcasts radio signals that can be received by all smart devices in the range.", @"It's a tiny computer that broadcasts radio signals that can be received by all smart devices in the range."), NSLocalizedString(@"View all data (a company's name, description, contacts etc.) that are linked to the nearest beacons.", @"View all data (a company's name, description, contacts etc.) that are linked to the nearest beacons."), NSLocalizedString(@"Create your own info cards and link them to a beacon, or even use your smart device as a beacon.", @"Create your own info cards and link them to a beacon, or even use your smart device as a beacon.")];
    self.dataSource = self;

    PBPageContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [self setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

    // Do any additional setup after loading the view.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = ((PBPageContentViewController *) viewController).index;

    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }

    index--;
    return [self viewControllerAtIndex:index];
}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = ((PBPageContentViewController *) viewController).index;

    if (index == NSNotFound) {
        return nil;
    }

    index++;
    if (index == [self.backgroundImages count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (PBPageContentViewController *)viewControllerAtIndex:(NSUInteger)index {
    PBPageContentViewController *pageContentViewController = (PBPageContentViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"PageContentViewController"];
    pageContentViewController.imageName = self.backgroundImages[index];
    pageContentViewController.titleString = self.titles[index];
    pageContentViewController.descriptionString = self.descriptions[index];
    pageContentViewController.index = index;

    return pageContentViewController;
}

@end
