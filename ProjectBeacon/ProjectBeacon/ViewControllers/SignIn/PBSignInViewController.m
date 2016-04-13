//
//  ViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 11/16/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <Google/SignIn.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <TwitterKit/TwitterKit.h>
#import "PBSignInViewController.h"
#import "PBApplicationFacade.h"
#import "Constants.h"


@interface PBSignInViewController () <GIDSignInDelegate, GIDSignInUIDelegate>

@end


@implementation PBSignInViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"signin_background"]];
    // Do any additional setup after loading the view, typically from a nib.
    [self.facebookButton setBackgroundImage:[[UIImage imageNamed:@"facebook_signin_button"] resizableImageWithCapInsets:UIEdgeInsetsMake(3, 50, 3, 30)] forState:UIControlStateNormal];
    [self.twitterButton setBackgroundImage:[[UIImage imageNamed:@"twitter_signin_button"] resizableImageWithCapInsets:UIEdgeInsetsMake(3, 50, 3, 30)] forState:UIControlStateNormal];
    [self.googleButton setBackgroundImage:[[UIImage imageNamed:@"google_signin_button"] resizableImageWithCapInsets:UIEdgeInsetsMake(3, 50, 3, 30)] forState:UIControlStateNormal];
    [self.facebookButton addTarget:self action:@selector(facebookButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.twitterButton addTarget:self action:@selector(twitterButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.googleButton addTarget:self action:@selector(googleButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.skipButton addTarget:self action:@selector(skipButtonClick) forControlEvents:UIControlEventTouchUpInside];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Actions


- (void)skipButtonClick {
    [[PBApplicationFacade sharedManager] skipLogin];
    [self performSegueWithIdentifier:@"SignInIdentifier" sender:self];
}


- (void)googleButtonClick {
    [GIDSignIn sharedInstance].delegate = self;
    [GIDSignIn sharedInstance].uiDelegate = self;
    [[GIDSignIn sharedInstance] signIn];
}


- (void)twitterButtonClick {
    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
        if (session) {
            [self loginWithAuthProvider:kTwitterAuthProvider authKey:[NSString stringWithFormat:@"token=%@,secret=%@", session.authToken, session.authTokenSecret]];
            DDLogInfo(@"signed in as %@", [session userName]);
        }
        else {
            [self showSignInErrorAlert];
            DDLogError(@"error: %@", [error localizedDescription]);
        }
    }];
}


- (void)facebookButtonClicked {
    if (![FBSDKAccessToken currentAccessToken]) {
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login logInWithReadPermissions:@[@"public_profile"] fromViewController:self handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (error) {
                [self showSignInErrorAlert];
                DDLogError(@"Process error");
            }
            else if (result.isCancelled) {
                [self showSignInErrorAlert];
                DDLogError(@"Cancelled");
            }
            else {
                DDLogInfo(@"Logged in");
                [self loginWithAuthProvider:kFacebookAuthProvider authKey:result.token.tokenString];
            }
        }];
    }
    else {
        [self loginWithAuthProvider:kFacebookAuthProvider authKey:[[FBSDKAccessToken currentAccessToken] tokenString]];
    }
}


#pragma mark - Google sign in delegate methods


- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    if (error) {
        [self showSignInErrorAlert];
        DDLogError(@"Process error");
    }
    else {
        DDLogInfo(@"Logged in");
        [self loginWithAuthProvider:kGoogleAuthProvider authKey:user.authentication.idToken];
    }
}


#pragma mark - Helper methods


- (void)loginWithAuthProvider:(NSString *)provider authKey:(NSString *)key {
    [[PBApplicationFacade sharedManager] loginWithAuthProvider:provider authKey:key callback:^(BOOL authResult) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            if (authResult) {
                [self performSegueWithIdentifier:@"SignInIdentifier" sender:self];
            }
            else {
                [self showSignInErrorAlert];
            }
        });

    }];
}


- (void)showSignInErrorAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sign in", @"Sign in") message:NSLocalizedString(@"Can't sign into application", @"Can't sign into application") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
