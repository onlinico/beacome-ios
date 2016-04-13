//
//  ViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 11/16/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBSignInViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UIButton *googleButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@end

