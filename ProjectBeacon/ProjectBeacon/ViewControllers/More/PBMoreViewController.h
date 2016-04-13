//
//  PBMoreViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/5/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBMoreViewController : UIViewController


@property (nonatomic, strong) id user;
@property (weak, nonatomic) IBOutlet UIImageView *userPicture;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;

- (IBAction)signOut:(id)sender;
- (IBAction)unwindMoreAndSave:(UIStoryboardSegue *)sender;
@end
