//
//  PBShareCardViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/14/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBShareCardViewController.h"
#import "PBPassDataDelegate.h"
#import "PBCardsShare.h"
#import "NSString+Extended.h"


@interface PBShareCardViewController () <UITextFieldDelegate>

@end


@implementation PBShareCardViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.emailTextField.delegate = self;
    if (!self.cardsShare) {
        self.cardsShare = [[PBCardsShare alloc] init];
        self.index = -1;
    }
    else {
        [self.sendButton setTitle:NSLocalizedString(@"Save", @"Save") forState:UIControlStateNormal];
        self.emailTextField.text = self.cardsShare.email;
        self.emailTextField.enabled = NO;
        self.ownerSwitch.on = self.cardsShare.permission;
    }

    UIGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.popupContentView addGestureRecognizer:tapper];

    [self.cancelButton setBackgroundImage:[[UIImage imageNamed:@"share_button_background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateNormal];
    [self.sendButton setBackgroundImage:[[UIImage imageNamed:@"share_button_background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateNormal];
    self.popupViewBackground.image = [[UIImage imageNamed:@"share_popup_background"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15) resizingMode:UIImageResizingModeStretch];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cancelAction:(id)sender {
    [self.emailTextField resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)sendAction:(id)sender {
    [self.emailTextField resignFirstResponder];
    if ([NSString isEmptyOrNil:self.emailTextField.text] || ![NSString validateEmail:self.emailTextField.text]) {
        [self setWarningOnTextField:self.emailTextField];
    }
    else {
        [self clearWarningOnTextField:self.emailTextField];
        self.cardsShare.email = self.emailTextField.text;
        self.cardsShare.permission = self.ownerSwitch.on;
        [self.delegate sender:self passData:self.cardsShare];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - Keyboard appearance methods


- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGSize keyboardSize = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    CGRect aRect = self.view.frame;
    aRect.size.height -= keyboardSize.height;

    if (!CGRectContainsPoint(aRect, CGPointMake(self.popupContentView.frame.origin.x, self.popupContentView.frame.origin.y + self.popupContentView.frame.size.height))) {

        [self.scrollView scrollRectToVisible:self.popupContentView.frame animated:YES];

    }
}


- (void)keyboardWillHide:(NSNotification *)note {
    // Get the keyboard size
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}


#pragma mark UITextField delegate methods


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self clearWarningOnTextField:self.emailTextField];
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([NSString isEmptyOrNil:self.emailTextField.text] || ![NSString validateEmail:self.emailTextField.text]) {
        [self setWarningOnTextField:self.emailTextField];
    }
}


#pragma mark - Helper methods


- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.emailTextField resignFirstResponder];
}


- (void)setWarningOnTextField:(UITextField *)textField {
    textField.layer.masksToBounds = YES;
    textField.layer.borderColor = [[UIColor redColor] CGColor];
    textField.layer.borderWidth = 1.0f;
}


- (void)clearWarningOnTextField:(UITextField *)textField {
    textField.layer.borderColor = [[UIColor clearColor] CGColor];
}

@end
