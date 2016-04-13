//
//  PBAccountViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/5/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PBAccountViewController : UIViewController


@property (nonatomic, strong) id user;
@property (nonatomic, assign) BOOL userIsChanged;

@property (weak, nonatomic) IBOutlet UIImageView *userPicture;
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *userEmail;

@property (weak, nonatomic) IBOutlet UIImageView *facebookImage;
@property (weak, nonatomic) IBOutlet UIImageView *twitterImage;
@property (weak, nonatomic) IBOutlet UIImageView *googleImage;

@property (weak, nonatomic) IBOutlet UILabel *facebookLabel;
@property (weak, nonatomic) IBOutlet UILabel *twitterLabel;
@property (weak, nonatomic) IBOutlet UILabel *googleLabel;

@property (weak, nonatomic) IBOutlet UIButton *addFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton *addTwitterButton;
@property (weak, nonatomic) IBOutlet UIButton *addGoogleButton;


- (IBAction)changeImage:(id)sender;
- (IBAction)addFacebook:(id)sender;
- (IBAction)addTwitter:(id)sender;
- (IBAction)addGoogle:(id)sender;
- (IBAction)saveChanges:(id)sender;

@end
