//
//  PBAccountViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/5/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBAccountViewController.h"
#import "PBApplicationFacade.h"
#import "PBError.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Google/SignIn.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <TwitterKit/TwitterKit.h>
#import "Constants.h"


@interface PBAccountViewController () <PBApplicationFacadeDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, GIDSignInDelegate, GIDSignInUIDelegate>


@property (nonatomic, strong) PBApplicationFacade *facade;

@end


@implementation PBAccountViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.facade = [PBApplicationFacade sharedManager];
    [self.navigationItem setHidesBackButton:YES];
    UIGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapper];
    self.userName.placeholder = NSLocalizedString(@"User name", @"User name");
    self.userEmail.placeholder = NSLocalizedString(@"User email", @"User email");
    // Do any additional setup after loading the view.

}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.facade.delegate = self;

    if (self.user) {
        self.userName.text = ((PBUser *) self.user).fullName;
        self.userEmail.text = ((PBUser *) self.user).email;
        dispatch_async(dispatch_get_main_queue(), ^() {
            self.userPicture.image = ((PBUser *) self.user).userPicture != nil ? [UIImage imageWithData:((PBUser *) self.user).userPicture] : [UIImage imageNamed:@"user_default_icon"];
            self.userPicture.layer.cornerRadius = self.userPicture.frame.size.width / 2;
            self.userPicture.clipsToBounds = YES;
        });

        [self setFacebookVisibility];
        [self setTwitterVisibility];
        [self setGoogleVisibility];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self saveEditing];
}


- (void)saveEditing {
    [self.userName endEditing:YES];
    [self.userEmail endEditing:YES];
    ((PBUser *) self.user).fullName = self.userName.text;
    ((PBUser *) self.user).email = self.userEmail.text;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self saveEditing];
}


#pragma mark - Actions


- (IBAction)changeImage:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:nil];
}


- (IBAction)addFacebook:(id)sender {
    __block FBSDKAccessToken *token;
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
                token = result.token;
            }
        }];
    }
    else {
        token = [FBSDKAccessToken currentAccessToken];
    }

    [self.facade linkSocial:token.tokenString toUser:self.user forType:kFacebookAuthProvider callback:^(BOOL result) {
        if (result) {
            [self setFacebookVisibility];
        }
        else{
            NSError *alertError = [NSError errorWithDomain:kPBErrorDomain code:kPBUIErrorCantConnectSocialNetworkCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBUIErrorCantConnectSocialNetwork]}];
            [self showAlertError:alertError];
        }
    }];
}


- (IBAction)addTwitter:(id)sender {
    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
        if (session) {
            [self.facade linkSocial:[NSString stringWithFormat:@"token=%@,secret=%@", session.authToken, session.authTokenSecret] toUser:self.user forType:kTwitterAuthProvider callback:^(BOOL result) {
                if (result) {
                    [self setTwitterVisibility];
                }
                else{
                    NSError *alertError = [NSError errorWithDomain:kPBErrorDomain code:kPBUIErrorCantConnectSocialNetworkCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBUIErrorCantConnectSocialNetwork]}];
                    [self showAlertError:alertError];
                }
            }];
            DDLogInfo(@"signed in as %@", [session userName]);
        }
        else {
            [self showSignInErrorAlert];
            DDLogError(@"error: %@", [error localizedDescription]);
        }
    }];
}


- (IBAction)addGoogle:(id)sender {
    [GIDSignIn sharedInstance].delegate = self;
    [GIDSignIn sharedInstance].uiDelegate = self;
    [[GIDSignIn sharedInstance] signIn];
}


- (IBAction)saveChanges:(id)sender {
    [self saveEditing];
}


#pragma mark - Google sign in delegate methods


- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    if (error) {
        [self showSignInErrorAlert];
        DDLogError(@"Process error");
    }
    else {
        DDLogInfo(@"Logged in");
        [self.facade linkSocial:user.authentication.idToken toUser:self.user forType:kGoogleAuthProvider callback:^(BOOL result) {
            if (result) {
                [self setGoogleVisibility];
            }
            else{
                NSError *alertError = [NSError errorWithDomain:kPBErrorDomain code:kPBUIErrorCantConnectSocialNetworkCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBUIErrorCantConnectSocialNetwork]}];
                [self showAlertError:alertError];
            }
        }];
    }
}


#pragma mark - Application facade delegate methods


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    [self showAlertError:error];
}


#pragma mark - Image picker delegate methods


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if ([info[UIImagePickerControllerMediaType] isEqualToString:(NSString *) kUTTypeImage]) {
        UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
        CGSize destinationSize = CGSizeMake(500, 500);
        UIGraphicsBeginImageContext(destinationSize);
        [selectedImage drawInRect:CGRectMake(0, 0, destinationSize.width, destinationSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.userPicture.image = newImage;
        ((PBUser *) self.user).userPicture = UIImagePNGRepresentation(newImage);
        self.userIsChanged = YES;
    }
    else {
        NSError *error = [NSError errorWithDomain:kPBErrorDomain code:kPBImagePickerErrorNotImageTypeCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBImagePickerErrorNotImageType]}];
        [self showAlertError:error];
    }
}


#pragma mark - Text fields delegate


- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isEqual:self.userName]) {
        self.userIsChanged = ![textField.text isEqualToString:((PBUser *) self.user).fullName];
    }
    else if ([textField isEqual:self.userEmail]) {
        self.userIsChanged = ![textField.text isEqualToString:((PBUser *) self.user).email];
    }
}


#pragma mark - Helper methods


- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.userName endEditing:YES];
    [self.userEmail endEditing:YES];
}


- (void)showSignInErrorAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sign in", @"Sign in") message:NSLocalizedString(@"Can't sign into application", @"Can't sign into application") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)setFacebookVisibility {
    if (((PBUser *) self.user).facebookIsLinked) {
        self.facebookImage.alpha = 1;
        self.facebookLabel.alpha = 1;
        self.addFacebookButton.hidden = YES;
    }
    else {
        self.facebookImage.alpha = 0.45;
        self.facebookLabel.alpha = 0.45;
        self.addFacebookButton.hidden = NO;
    }
}


- (void)setTwitterVisibility {
    if (((PBUser *) self.user).twitterIsLinked) {
        self.twitterImage.alpha = 1;
        self.twitterLabel.alpha = 1;
        self.addTwitterButton.hidden = YES;
    }
    else {
        self.twitterImage.alpha = 0.45;
        self.twitterLabel.alpha = 0.45;
        self.addTwitterButton.hidden = NO;
    }
}


- (void)setGoogleVisibility {
    if (((PBUser *) self.user).gPlusIsLinked) {
        self.googleImage.alpha = 1;
        self.googleLabel.alpha = 1;
        self.addGoogleButton.hidden = YES;
    }
    else {
        self.googleImage.alpha = 0.45;
        self.googleLabel.alpha = 0.45;
        self.addGoogleButton.hidden = NO;
    }
}


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
