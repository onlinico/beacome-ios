//
//  PBAddVCardViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/14/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "PBAddVCardViewController.h"
#import "PBCardTextTableViewCell.h"
#import "PBPassDataDelegate.h"
#import "PBCardImageTableViewCell.h"
#import "PBVCard.h"
#import "PBError.h"
#import "NSString+Extended.h"


typedef NS_ENUM(NSUInteger, VCardSections) {
    NewCardSectionsImageSection,
    NewCardSectionsTextSection
};


@interface PBAddVCardViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>


@property (nonatomic, strong) NSIndexPath *selectedRow;
@property (nonatomic, strong) UITextField *selectedTextField;
@property (nonatomic, assign) NSUInteger validationErrorCount;

@end


@implementation PBAddVCardViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (!self.vCard) {
        self.vCard = [[PBVCard alloc] init];
        self.index = -1;
    }
    else {
        [self.addButton setTitle:NSLocalizedString(@"Save", @"Save")];
    }

    UIGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapper];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    // Do any additional setup after loading the view.
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

#pragma mark - Table view data source methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 8;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case NewCardSectionsImageSection: {
            return 1;
        }
        case NewCardSectionsTextSection: {
            return 3;
        }
        default:
            break;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case NewCardSectionsImageSection: {
            cell = (PBCardImageTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"CardImageCellIdentifier"];
            dispatch_async(dispatch_get_main_queue(), ^{
                ((PBCardImageTableViewCell *) cell).cardImage.image = self.vCard.personImage ? [UIImage imageWithData:self.vCard.personImage] : [UIImage imageNamed:@"user_default_icon"];
                ((PBCardImageTableViewCell *) cell).cardImage.layer.cornerRadius = ((PBCardImageTableViewCell *) cell).cardImage.frame.size.width / 2;
                ((PBCardImageTableViewCell *) cell).cardImage.clipsToBounds = YES;
            });
            [((PBCardImageTableViewCell *) cell).chooseImageButton addTarget:self action:@selector(chooseImage:) forControlEvents:UIControlEventTouchUpInside];
            break;
        }
        case NewCardSectionsTextSection: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"CardTextCellIdentifier"];
            if (indexPath.row == 0) {
                ((PBCardTextTableViewCell *) cell).cardText.delegate = self;
                ((PBCardTextTableViewCell *) cell).cardText.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Name", @"Name") attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor], NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:16]}];
                ((PBCardTextTableViewCell *) cell).cardText.text = self.vCard.fullName;
                ((PBCardTextTableViewCell *) cell).cardText.keyboardType = UIKeyboardTypeAlphabet;
            }
            else if (indexPath.row == 1) {
                ((PBCardTextTableViewCell *) cell).cardText.delegate = self;
                ((PBCardTextTableViewCell *) cell).cardText.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Email", @"Email") attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor], NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:16]}];
                ((PBCardTextTableViewCell *) cell).cardText.text = self.vCard.email;
                ((PBCardTextTableViewCell *) cell).cardText.keyboardType = UIKeyboardTypeEmailAddress;
            }
            else {
                ((PBCardTextTableViewCell *) cell).cardText.delegate = self;
                ((PBCardTextTableViewCell *) cell).cardText.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Phone", @"Phone") attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor], NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:16]}];
                ((PBCardTextTableViewCell *) cell).cardText.text = self.vCard.phone;
                ((PBCardTextTableViewCell *) cell).cardText.keyboardType = UIKeyboardTypePhonePad;
            }
            break;
        }
        default:
            break;
    }
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case NewCardSectionsImageSection: {
            return 136;
        }
        case NewCardSectionsTextSection: {
            return 44;
        }
        default:
            break;
    }
    return 44;
}


#pragma mark - Table view delegate methods

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
        self.vCard.personImage = UIImagePNGRepresentation(newImage);

        dispatch_async(dispatch_get_main_queue(), ^() {
            PBCardImageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:NewCardSectionsImageSection]];
            cell.cardImage.image = newImage;
        });
    }
    else {
        NSError *error = [NSError errorWithDomain:kPBErrorDomain code:kPBImagePickerErrorNotImageTypeCode userInfo:@{NSLocalizedDescriptionKey : kPBImagePickerErrorNotImageType}];
        [self showAlertError:error];
    }
}


#pragma mark - Keyboard appearance methods


- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGSize keyboardSize = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;

    // Scroll the table view to see the TextField just above the keyboard
    if (self.selectedTextField) {
        CGRect textFieldRect = [self.tableView convertRect:self.selectedTextField.bounds fromView:self.selectedTextField];
        [self.tableView scrollRectToVisible:textFieldRect animated:NO];
    }
}


- (void)keyboardWillHide:(NSNotification *)note {
    // Get the keyboard size
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}


#pragma mark - Text field delegate methods


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.selectedTextField = textField;
    [self clearWarningOnTextField:textField];
    CGPoint touchPoint = [textField convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    self.selectedRow = indexPath;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.selectedTextField = nil;
    switch (self.selectedRow.section) {
        case NewCardSectionsTextSection: {
            if (self.selectedRow.row == 0) {
                if ([NSString isEmptyOrNil:textField.text]) {
                    [self setWarningOnTextField:textField];
                    self.validationErrorCount++;
                }
                else {
                    self.vCard.fullName = textField.text;
                    if (self.validationErrorCount > 0) {
                        self.validationErrorCount--;
                    }
                }

            }
            else if (self.selectedRow.row == 1) {
                if (![NSString validateEmail:textField.text] || [NSString isEmptyOrNil:textField.text]) {
                    [self setWarningOnTextField:textField];
                    self.validationErrorCount++;
                }
                else {
                    self.vCard.email = textField.text;
                    if (self.validationErrorCount > 0) {
                        self.validationErrorCount--;
                    }
                }
            }
            else {
                if (![NSString validatePhone:textField.text] || [NSString isEmptyOrNil:textField.text]) {
                    [self setWarningOnTextField:textField];
                    self.validationErrorCount++;
                }
                else {
                    self.vCard.phone = textField.text;
                    if (self.validationErrorCount > 0) {
                        self.validationErrorCount--;
                    }
                }
            }
            break;
        }
        default:
            break;
    }
}


#pragma mark - Actions


- (IBAction)cancelAction:(id)sender {
    [self.selectedTextField resignFirstResponder];
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)addAction:(id)sender {
    [self.selectedTextField resignFirstResponder];
    if (self.validationErrorCount == 0 && ![NSString isEmptyOrNil:self.vCard.fullName] && ![NSString isEmptyOrNil:self.vCard.email] && ![NSString isEmptyOrNil:self.vCard.phone]) {
        [self.vCard createVCardData];
        [self.delegate sender:self passData:self.vCard];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        if ([NSString isEmptyOrNil:self.vCard.fullName]) {
            PBCardTextTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:NewCardSectionsTextSection]];
            [self setWarningOnTextField:cell.cardText];
        }
        if ([NSString isEmptyOrNil:self.vCard.email]) {
            PBCardTextTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:NewCardSectionsTextSection]];
            [self setWarningOnTextField:cell.cardText];
        }
        if ([NSString isEmptyOrNil:self.vCard.phone]) {
            PBCardTextTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:NewCardSectionsTextSection]];
            [self setWarningOnTextField:cell.cardText];
        }
        NSError *error = [NSError errorWithDomain:kPBErrorDomain code:kPBUIErrorDataIsNotValidCode userInfo:@{NSLocalizedDescriptionKey : kPBUIErrorDataIsNotValid}];
        [self showAlertError:error];
    }
}


#pragma mark - Helper methods


- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.selectedTextField resignFirstResponder];
}


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)chooseImage:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:nil];
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
