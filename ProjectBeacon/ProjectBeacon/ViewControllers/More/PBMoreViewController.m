//
//  PBMoreViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/5/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBMoreViewController.h"
#import "PBApplicationFacade.h"
#import "PBAccountViewController.h"
#import "PBSignInViewController.h"
#import "PBMoreTableViewController.h"
#import "PBError.h"
#import "Constants.h"


@interface PBMoreViewController () <PBApplicationFacadeDelegate>


@property (nonatomic, strong) PBApplicationFacade *facade;
@property (nonatomic, assign) BOOL saving;

@end


@implementation PBMoreViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.facade = [PBApplicationFacade sharedManager];
    // Do any additional setup after loading the view.
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.facade.delegate = self;
    if (self.facade.isAnonymus) {
        [self.signInButton setTitle:NSLocalizedString(@"SIGN IN", @"SIGN IN") forState:UIControlStateNormal];
    }
    if (!self.saving) {
        [self loadUser];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods{
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Application facade delegate methods


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedUserInfo:(PBUser *)user {
    [self updateUserInfo:user];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:[PBError checkAndCreateInApplicationError:error]];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailBluetoothServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:error];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didUpdateBluetoothStatus:(BOOL)status {
    [(PBMoreTableViewController *) self.childViewControllers.firstObject updateBluetoothStatus:status];
}


#pragma mark - Actions


- (IBAction)signOut:(id)sender {
    if (self.facade.isAnonymus) {
        PBSignInViewController *signInViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
        [self presentViewController:signInViewController animated:YES completion:nil];
    }
    else {
        self.signInButton.enabled = NO;
        [self.facade signOutWithCallback:^(BOOL success) {
            if (success) {
                PBSignInViewController *signInViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
                [self presentViewController:signInViewController animated:YES completion:nil];
            }
            else {
                NSError *error = [NSError errorWithDomain:kPBErrorDomain code:kPBUIErrorCantSignOutCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBUIErrorCantSignOut]}];
                [self showAlertError:error];
            }
            self.signInButton.enabled = YES;
        }];

    }

}


- (IBAction)unwindMoreAndSave:(UIStoryboardSegue *)sender {
    if ([sender.sourceViewController isMemberOfClass:[PBAccountViewController class]]) {
        PBAccountViewController *accountViewController = sender.sourceViewController;
        if (accountViewController.userIsChanged) {
            self.saving = YES;
            self.userPicture.image = [UIImage imageWithData:((PBUser *) self.user).userPicture];
            [self.facade saveUser:self.user callback:^(BOOL result) {
                if (!result) {
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        [self showSaveUserAlert];
                    });
                }
                else{
                    [self updateUserInfo:self.user];
                }
                self.saving = NO;
            }];
        }
    }
}


#pragma mark - Helper methods


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)showSaveUserAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:NSLocalizedString(@"User can't be saved due to service error.\n Try to save it once more?", @"User can't be saved due to service error.\n Try to save it once more?") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction *handler) {
        [self.facade saveUser:self.user callback:^(BOOL result) {
            [self showSaveUserAlert];
        }];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)loadUser {
    [self.facade getCurrentUserInfo:^(PBUser *user) {
        [self updateUserInfo:user];
    }];
}


- (void)updateUserInfo:(PBUser *)user {
    self.user = user;
    self.userName.text = user.fullName;
    self.userPicture.image = user.userPicture != nil ? [UIImage imageWithData:user.userPicture] : [UIImage imageNamed:@"user_default_icon"];
    self.userPicture.layer.cornerRadius = self.userPicture.frame.size.width / 2;
    self.userPicture.clipsToBounds = YES;
}

@end
