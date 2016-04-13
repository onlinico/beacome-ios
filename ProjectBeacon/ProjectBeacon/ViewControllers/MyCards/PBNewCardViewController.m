//
//  PBNewCardViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/12/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <ContactsUI/ContactsUI.h>
#import <AddressBookUI/AddressBookUI.h>
#import "PBNewCardViewController.h"
#import "PBCardImageTableViewCell.h"
#import "PBCardContactTableViewCell.h"
#import "PBPassDataDelegate.h"
#import "PBVCardTableViewCell.h"
#import "PBBeaconTableViewCell.h"
#import "PBShareCardTableViewCell.h"
#import "PBAddContactTableViewCell.h"
#import "PBCard.h"
#import "NSString+Enum.h"
#import "PBCardTextTableViewCell.h"
#import "PBError.h"
#import "PBCardSectionHeaderView.h"
#import "PBShareCardViewController.h"
#import "PBLinkBeaconViewController.h"
#import "PBAddVCardViewController.h"
#import "PBvCard.h"
#import "PBBeacon.h"
#import "PBCardsShare.h"
#import "PBApplicationFacade.h"
#import "Constants.h"
#import "NSString+GUID.h"
#import "NSString+Extended.h"


typedef NS_ENUM(NSUInteger, NewCardSections) {
    NewCardSectionsImageSection,
    NewCardSectionsTextSection,
    NewCardSectionsPhonesSection,
    NewCardSectionsEmailsSection,
    NewCardSectionsUrlsSection,
    NewCardSectionsVCardSection,
    NewCardSectionsBeaconsSection,
    NewCardSectionsShareSection
};


@interface PBNewCardViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PBPassDataDelegate, CNContactPickerDelegate, ABPeoplePickerNavigationControllerDelegate>


@property (nonatomic, strong) NSMutableArray *phones;
@property (nonatomic, strong) NSMutableArray *emails;
@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) NSMutableArray *vCards;
@property (nonatomic, strong) NSMutableArray *shareContacts;
@property (nonatomic, strong) NSMutableArray *linkedBeacons;

@property (nonatomic, strong) NSIndexPath *selectedRow;
@property (nonatomic, strong) UITextField *selectedTextField;

@property (nonatomic, strong) PBApplicationFacade *facade;

@property (nonatomic, strong) NSMutableArray *nonValidatedRows;
@property (nonatomic, assign) BOOL pickerIsShow;

@end


@implementation PBNewCardViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.facade = [PBApplicationFacade sharedManager];
    self.nonValidatedRows = [NSMutableArray array];

    UIGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapper];

    if (!self.card) {
        if (!self.card) {
            self.card = [[PBCard alloc] init];
        }
        self.card.permission = PBCardPermissionOwner;
        self.title = NSLocalizedString(@"New Card", @"New Card");
        self.phones = [NSMutableArray array];
        self.emails = [NSMutableArray array];
        self.urls = [NSMutableArray array];
        self.vCards = [NSMutableArray array];
        self.shareContacts = [NSMutableArray array];
        self.linkedBeacons = [NSMutableArray array];
    }
    else {
        self.title = self.card.title;
        self.phones = [self.card.phones mutableCopy];
        self.emails = [self.card.emails mutableCopy];
        self.urls = [self.card.urls mutableCopy];
        self.vCards = [self.card.vCards mutableCopy];
        self.shareContacts = [self.card.cardShare mutableCopy];
        self.linkedBeacons = [self.card.beacons mutableCopy];
    }

    self.actionsToolbar.tintColor = [UIColor lightGrayColor];
    self.linkOffButton.enabled = NO;
    self.linkOnButton.enabled = NO;
    self.shareChangingButton.enabled = NO;
    self.vCardButton.enabled = NO;
    self.deleteButton.enabled = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self.tableView registerNib:[UINib nibWithNibName:@"PBCardSectionHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"PBCardSectionHeaderView"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


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
            return 2;
        }
        case NewCardSectionsPhonesSection: {
            return self.phones.count + 1;
        }
        case NewCardSectionsEmailsSection: {
            return self.emails.count + 1;
        }
        case NewCardSectionsUrlsSection: {
            return self.urls.count + 1;
        }
        case NewCardSectionsVCardSection: {
            return self.vCards.count;
        }
        case NewCardSectionsBeaconsSection: {
            return self.linkedBeacons.count;
        }
        case NewCardSectionsShareSection: {
            return self.shareContacts.count;
        }
        default:
            break;
    }
    return 0;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *result = nil;
    switch (section) {
        case NewCardSectionsVCardSection: {
            PBCardSectionHeaderView *headerView = (id) [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"PBCardSectionHeaderView"];
            headerView.headerTitle.text = NSLocalizedString(@"People", @"People");
            headerView.addButton.tag = section;
            headerView.addButton.enabled = self.card.permission;
            [headerView.addButton addTarget:self action:@selector(addItemFromHeader:) forControlEvents:UIControlEventTouchUpInside];
            result = headerView;
            break;
        }
        case NewCardSectionsBeaconsSection: {
            PBCardSectionHeaderView *headerView = (id) [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"PBCardSectionHeaderView"];
            headerView.headerTitle.text = NSLocalizedString(@"Card Beacons", @"Card Beacons");
            headerView.addButton.tag = section;
            [headerView.addButton addTarget:self action:@selector(addItemFromHeader:) forControlEvents:UIControlEventTouchUpInside];
            result = headerView;
            break;
        }
        case NewCardSectionsShareSection: {
            PBCardSectionHeaderView *headerView = (id) [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"PBCardSectionHeaderView"];
            headerView.headerTitle.text = NSLocalizedString(@"Card Share With", @"Card Share With");
            headerView.addButton.tag = section;
            headerView.addButton.enabled = self.card.permission;
            [headerView.addButton addTarget:self action:@selector(addItemFromHeader:) forControlEvents:UIControlEventTouchUpInside];
            result = headerView;
            break;
        }
        case NewCardSectionsImageSection:
        case NewCardSectionsTextSection:
        case NewCardSectionsPhonesSection:
        case NewCardSectionsEmailsSection:
        case NewCardSectionsUrlsSection:
        default:
            break;
    }

    return result;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case NewCardSectionsVCardSection:
        case NewCardSectionsBeaconsSection:
        case NewCardSectionsShareSection: {
            return 62.0;
        }
        case NewCardSectionsImageSection:
        case NewCardSectionsTextSection:
        case NewCardSectionsPhonesSection:
        case NewCardSectionsEmailsSection:
        case NewCardSectionsUrlsSection: {
            return 28.0;
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
                ((PBCardImageTableViewCell *) cell).cardImage.image = self.card.logo ? [UIImage imageWithData:self.card.logo] : [UIImage imageNamed:@"card_default_icon"];
                ((PBCardImageTableViewCell *) cell).cardImage.layer.cornerRadius = ((PBCardImageTableViewCell *) cell).cardImage.frame.size.width / 2;
                ((PBCardImageTableViewCell *) cell).cardImage.clipsToBounds = YES;
            });
            [((PBCardImageTableViewCell *) cell).chooseImageButton addTarget:self action:@selector(chooseImage:) forControlEvents:UIControlEventTouchUpInside];
            [((PBCardImageTableViewCell *) cell) setEnabled:YES];
            if (![NSString isEmptyOrNil:self.card.cardId] && !self.card.permission) {
                [((PBCardImageTableViewCell *) cell) setEnabled:NO];
            }
            break;
        }
        case NewCardSectionsTextSection: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"CardTextCellIdentifier"];
            if (indexPath.row == 0) {
                ((PBCardTextTableViewCell *) cell).cardText.delegate = self;
                ((PBCardTextTableViewCell *) cell).cardText.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Card Name", @"Card Name") attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor], NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:16]}];
                ((PBCardTextTableViewCell *) cell).cardText.text = self.card.title;
            }
            else {
                ((PBCardTextTableViewCell *) cell).cardText.delegate = self;
                ((PBCardTextTableViewCell *) cell).cardText.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Description", @"Description") attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor], NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:16]}];
                ((PBCardTextTableViewCell *) cell).cardText.text = self.card.summary;
            }
            [((PBCardTextTableViewCell *) cell) setEnabled:YES];
            if (![NSString isEmptyOrNil:self.card.cardId] && !self.card.permission) {
                [((PBCardTextTableViewCell *) cell) setEnabled:NO];
            }
            break;
        }
        case NewCardSectionsPhonesSection: {
            if (indexPath.row < self.phones.count) {
                PBCardPhone *phone = nil;
                if (self.phones.count > indexPath.row) {
                    phone = self.phones[(NSUInteger) indexPath.row];
                }
                cell = (PBCardContactTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"CardContactCellIdentifier"];
                [((PBCardContactTableViewCell *) cell).removeContactButton addTarget:self action:@selector(removeItem:) forControlEvents:UIControlEventTouchUpInside];
                ((PBCardContactTableViewCell *) cell).contact.delegate = self;
                ((PBCardContactTableViewCell *) cell).contact.keyboardType = UIKeyboardTypePhonePad;
                ((PBCardContactTableViewCell *) cell).contact.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter number", @"Enter number") attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor], NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:16]}];

                if (phone) {
                    [((PBCardContactTableViewCell *) cell).contactType addTarget:self action:@selector(openSelector:) forControlEvents:UIControlEventTouchUpInside];
                    [((PBCardContactTableViewCell *) cell).contactType setTitle:[NSString stringFromPhoneType:phone.phoneType] forState:UIControlStateNormal];
                    ((PBCardContactTableViewCell *) cell).contact.text = phone.phoneNumber;
                }
                [((PBCardContactTableViewCell *) cell) setEnabled:YES];
                if (![NSString isEmptyOrNil:self.card.cardId] && !self.card.permission) {
                    [((PBCardContactTableViewCell *) cell) setEnabled:NO];
                }
            }
            else {
                cell = (PBAddContactTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"AddContactCellIdentifier"];
                [((PBAddContactTableViewCell *) cell).addContactButton addTarget:self action:@selector(addItem:) forControlEvents:UIControlEventTouchUpInside];
                ((PBAddContactTableViewCell *) cell).contactTypePlaceholder.text = NSLocalizedString(@"Add Phone Number", @"Add Phone Number");
                [((PBAddContactTableViewCell *) cell) setEnabled:YES];
                if (![NSString isEmptyOrNil:self.card.cardId] && !self.card.permission) {
                    [((PBAddContactTableViewCell *) cell) setEnabled:NO];
                }
            }

            break;
        }
        case NewCardSectionsEmailsSection: {
            if (indexPath.row < self.emails.count) {
                PBCardEmail *email = nil;
                if (self.emails.count > indexPath.row) {
                    email = self.emails[(NSUInteger) indexPath.row];
                }
                cell = (PBCardContactTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"CardContactCellIdentifier"];
                [((PBCardContactTableViewCell *) cell).removeContactButton addTarget:self action:@selector(removeItem:) forControlEvents:UIControlEventTouchUpInside];
                ((PBCardContactTableViewCell *) cell).contact.delegate = self;
                ((PBCardContactTableViewCell *) cell).contact.keyboardType = UIKeyboardTypeEmailAddress;
                ((PBCardContactTableViewCell *) cell).contact.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter email", @"Enter email") attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor], NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:16]}];

                if (email) {
                    [((PBCardContactTableViewCell *) cell).contactType addTarget:self action:@selector(openSelector:) forControlEvents:UIControlEventTouchUpInside];
                    [((PBCardContactTableViewCell *) cell).contactType setTitle:[NSString stringFromEmailType:email.emailType] forState:UIControlStateNormal];
                    ((PBCardContactTableViewCell *) cell).contact.text = email.email;
                }
                [((PBCardContactTableViewCell *) cell) setEnabled:YES];
                if (![NSString isEmptyOrNil:self.card.cardId] && !self.card.permission) {
                    [((PBCardContactTableViewCell *) cell) setEnabled:NO];
                }
            }
            else {
                cell = (PBAddContactTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"AddContactCellIdentifier"];
                [((PBAddContactTableViewCell *) cell).addContactButton addTarget:self action:@selector(addItem:) forControlEvents:UIControlEventTouchUpInside];
                ((PBAddContactTableViewCell *) cell).contactTypePlaceholder.text = NSLocalizedString(@"Add Email", @"Add Email");
                [((PBAddContactTableViewCell *) cell) setEnabled:YES];
                if (![NSString isEmptyOrNil:self.card.cardId] && !self.card.permission) {
                    [((PBAddContactTableViewCell *) cell) setEnabled:NO];
                }
            }
            break;
        }
        case NewCardSectionsUrlsSection: {
            if (indexPath.row < self.urls.count) {
                PBCardURL *url = nil;
                if (self.urls.count > indexPath.row) {
                    url = self.urls[(NSUInteger) indexPath.row];
                }
                cell = (PBCardContactTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"CardContactCellIdentifier"];
                [((PBCardContactTableViewCell *) cell).removeContactButton addTarget:self action:@selector(removeItem:) forControlEvents:UIControlEventTouchUpInside];
                ((PBCardContactTableViewCell *) cell).contact.delegate = self;
                ((PBCardContactTableViewCell *) cell).contact.keyboardType = UIKeyboardTypeURL;
                ((PBCardContactTableViewCell *) cell).contact.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter url", @"Enter url") attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor], NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:16]}];

                if (url) {
                    [((PBCardContactTableViewCell *) cell).contactType addTarget:self action:@selector(openSelector:) forControlEvents:UIControlEventTouchUpInside];
                    [((PBCardContactTableViewCell *) cell).contactType setTitle:[NSString stringFromUrlType:url.urlType] forState:UIControlStateNormal];
                    ((PBCardContactTableViewCell *) cell).contact.text = url.url;
                }
                [((PBCardContactTableViewCell *) cell) setEnabled:YES];
                if (![NSString isEmptyOrNil:self.card.cardId] && !self.card.permission) {
                    [((PBCardContactTableViewCell *) cell) setEnabled:NO];
                }
            }
            else {
                cell = (PBAddContactTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"AddContactCellIdentifier"];
                [((PBAddContactTableViewCell *) cell).addContactButton addTarget:self action:@selector(addItem:) forControlEvents:UIControlEventTouchUpInside];
                ((PBAddContactTableViewCell *) cell).contactTypePlaceholder.text = NSLocalizedString(@"Add URL", @"Add URL");
                [((PBAddContactTableViewCell *) cell) setEnabled:YES];
                if (![NSString isEmptyOrNil:self.card.cardId] && !self.card.permission) {
                    [((PBAddContactTableViewCell *) cell) setEnabled:NO];
                }
            }
            break;
        }
        case NewCardSectionsVCardSection: {
            cell = (PBVCardTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"VCardCellIdentifier"];
            if (self.vCards.count > indexPath.row) {
                PBVCard *vCard = self.vCards[(NSUInteger) indexPath.row];
                ((PBVCardTableViewCell *) cell).vCardFullName.text = vCard.fullName;
                ((PBVCardTableViewCell *) cell).vCardEmail.text = vCard.email;
                ((PBVCardTableViewCell *) cell).vCardPhone.text = vCard.phone;
                dispatch_async(dispatch_get_main_queue(), ^{
                    ((PBVCardTableViewCell *) cell).vCardImage.image = vCard.personImage ? [UIImage imageWithData:vCard.personImage] : [UIImage imageNamed:@"user_default_icon"];
                    ((PBVCardTableViewCell *) cell).vCardImage.layer.cornerRadius = ((PBVCardTableViewCell *) cell).vCardImage.frame.size.width / 2;
                    ((PBVCardTableViewCell *) cell).vCardImage.clipsToBounds = YES;
                });
                [((PBVCardTableViewCell *) cell) setEnabled:YES];
                if (![NSString isEmptyOrNil:self.card.cardId] && !self.card.permission) {
                    [((PBVCardTableViewCell *) cell) setEnabled:NO];
                }
            }

            break;
        }
        case NewCardSectionsBeaconsSection: {
            cell = (PBBeaconTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"BeaconCellIdentifier"];
            if (self.linkedBeacons.count > indexPath.row) {
                PBBeacon *beacon = self.linkedBeacons[(NSUInteger) indexPath.row];
                ((PBBeaconTableViewCell *) cell).beaconUid.text = beacon.beaconUid;
                ((PBBeaconTableViewCell *) cell).linkedCardsCount.text = [NSString stringWithFormat:@"%ld", (long) beacon.linkedCardsCount];
                [((PBBeaconTableViewCell *) cell) setEnabled:beacon.state];
            }
            break;
        }
        case NewCardSectionsShareSection: {
            cell = (PBShareCardTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"ShareContactCellIdentifier"];
            if (self.shareContacts.count > indexPath.row) {
                PBCardsShare *cardsShare = self.shareContacts[(NSUInteger) indexPath.row];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ((PBShareCardTableViewCell *) cell).userImage.image = cardsShare.photo ? [UIImage imageWithData:cardsShare.photo] : [UIImage imageNamed:@"user_default_icon"];
                    ((PBShareCardTableViewCell *) cell).userImage.layer.cornerRadius = ((PBShareCardTableViewCell *) cell).userImage.frame.size.width / 2;
                    ((PBShareCardTableViewCell *) cell).userImage.clipsToBounds = YES;
                });
                ((PBShareCardTableViewCell *) cell).email.text = cardsShare.email;
                ((PBShareCardTableViewCell *) cell).fullName.text = cardsShare.name ? cardsShare.name : NSLocalizedString(@"Invited user", @"Invited user");
                ((PBShareCardTableViewCell *) cell).permission.text = [NSString stringFromCardPermission:(PBCardPermission) cardsShare.permission];
            }
            [((PBShareCardTableViewCell *) cell) setEnabled:YES];
            if (![NSString isEmptyOrNil:self.card.cardId] && !self.card.permission) {
                [((PBShareCardTableViewCell *) cell) setEnabled:NO];
            }
            break;
        }
        default:
            break;
    }
    [cell setNeedsLayout];

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
        case NewCardSectionsPhonesSection: {
            if (indexPath.row < self.phones.count) {
                return 88;
            }
            else {
                return 44;
            }
        }
        case NewCardSectionsEmailsSection: {
            if (indexPath.row < self.emails.count) {
                return 88;
            }
            else {
                return 44;
            }
        }
        case NewCardSectionsUrlsSection: {
            if (indexPath.row < self.urls.count) {
                return 88;
            }
            else {
                return 44;
            }
        }
        case NewCardSectionsVCardSection: {
            return 100;
        }
        case NewCardSectionsBeaconsSection: {
            return 80;
        }
        case NewCardSectionsShareSection: {
            return 100;
        }
        default:
            break;
    }
    return 44;
}


#pragma mark - Table view delegate methods


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.card && !self.card.permission && indexPath.section != NewCardSectionsBeaconsSection) {
        return;
    }
    self.selectedRow = indexPath;
    switch (indexPath.section) {
        case NewCardSectionsVCardSection: {
            self.actionsToolbar.tintColor = kToolbarActiveTintColor;
            self.linkOffButton.enabled = NO;
            self.linkOnButton.enabled = NO;
            self.shareChangingButton.enabled = NO;
            self.vCardButton.enabled = YES;
            self.deleteButton.enabled = YES;
            break;
        }
        case NewCardSectionsBeaconsSection: {
            PBBeacon *beacon = self.linkedBeacons[(NSUInteger) indexPath.row];
            if (beacon.state) {
                self.linkOffButton.enabled = YES;
                self.linkOnButton.enabled = NO;
            }
            else {
                self.linkOffButton.enabled = NO;
                self.linkOnButton.enabled = YES;
            }
            self.actionsToolbar.tintColor = kToolbarActiveTintColor;
            self.shareChangingButton.enabled = NO;
            self.vCardButton.enabled = NO;
            self.deleteButton.enabled = YES;
            break;
        }
        case NewCardSectionsShareSection: {
            self.actionsToolbar.tintColor = kToolbarActiveTintColor;
            self.linkOffButton.enabled = NO;
            self.linkOnButton.enabled = NO;
            self.shareChangingButton.enabled = YES;
            self.vCardButton.enabled = NO;
            self.deleteButton.enabled = YES;
            break;
        }
        default: {
            self.actionsToolbar.tintColor = [UIColor lightGrayColor];
            self.linkOffButton.enabled = NO;
            self.linkOnButton.enabled = NO;
            self.shareChangingButton.enabled = NO;
            self.vCardButton.enabled = NO;
            self.deleteButton.enabled = NO;
        }
            break;
    }
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedRow = nil;
    self.actionsToolbar.tintColor = [UIColor lightGrayColor];
    self.linkOffButton.enabled = NO;
    self.linkOnButton.enabled = NO;
    self.shareChangingButton.enabled = NO;
    self.vCardButton.enabled = NO;
    self.deleteButton.enabled = NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
        self.card.logo = UIImagePNGRepresentation(newImage);

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
                    [self setWarningOnRow:self.selectedRow];
                }
                else {
                    self.card.title = textField.text;
                    [self clearWarningOnRow:self.selectedRow];
                }
            }
            else {
                self.card.summary = textField.text;
            }
            break;
        }
        case NewCardSectionsPhonesSection: {
            PBCardPhone *phone = self.phones[(NSUInteger) self.selectedRow.row];
            if (![NSString validatePhone:textField.text]) {
                [self setWarningOnRow:self.selectedRow];
            }
            else {
                phone.phoneNumber = textField.text;
                [self clearWarningOnRow:self.selectedRow];
            }

            break;
        }
        case NewCardSectionsEmailsSection: {
            PBCardEmail *email = self.emails[(NSUInteger) self.selectedRow.row];
            if (![NSString validateEmail:textField.text]) {
                [self setWarningOnRow:self.selectedRow];
            }
            else {
                email.email = textField.text;
                [self clearWarningOnRow:self.selectedRow];
            }

            break;
        }
        case NewCardSectionsUrlsSection: {
            PBCardURL *url = self.urls[(NSUInteger) self.selectedRow.row];
            if (url.urlType != PBUrlWebsite) {
                url.url = textField.text;
            }
            else {
                if (![NSString validateURL:textField.text]) {
                    [self setWarningOnRow:self.selectedRow];
                }
                else {
                    url.url = textField.text;
                    [self clearWarningOnRow:self.selectedRow];
                }
            }


            break;
        }
        default:
            break;
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


#pragma mark - Picker delegate and datasource methods


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    switch (pickerView.tag) {
        case 100: {
            return 6;
        }
        case 200: {
            return 3;
        }
        case 300: {
            return 2;
        }
        default:
            break;
    }
    return 0;
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *result = nil;
    switch (pickerView.tag) {
        case 100: {
            result = [NSString stringFromPhoneType:(PBPhoneType) (101 + row)];
            break;
        }
        case 200: {
            result = [NSString stringFromEmailType:(PBEmailType) (201 + row)];
            break;
        }
        case 300: {
            result = [NSString stringFromUrlType:(PBUrlType) (301 + row)];
            break;
        }
        default:
            break;
    }
    return result;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

    PBCardContactTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.selectedRow];
    NSString *result = nil;
    switch (pickerView.tag) {
        case 100: {
            PBPhoneType phoneType = (PBPhoneType) (101 + row);
            PBCardPhone *phone = self.phones[(NSUInteger) self.selectedRow.row];
            phone.phoneType = phoneType;
            result = [NSString stringFromPhoneType:phoneType];
            break;
        }
        case 200: {
            PBEmailType emailType = (PBEmailType) (201 + row);
            PBCardEmail *email = self.emails[(NSUInteger) self.selectedRow.row];
            email.emailType = emailType;
            result = [NSString stringFromEmailType:emailType];
            break;
        }
        case 300: {
            PBUrlType urlType = (PBUrlType) (301 + row);
            PBCardURL *url = self.urls[(NSUInteger) self.selectedRow.row];
            url.urlType = urlType;
            result = [NSString stringFromUrlType:urlType];

            if (urlType == PBUrlSkype) {
                [self clearWarningOnRow:self.selectedRow];
            }
            else {
                if ([NSString validateURL:cell.contact.text]) {
                    [self clearWarningOnRow:self.selectedRow];
                }
                else {
                    [self setWarningOnRow:self.selectedRow];
                }
            }
            break;
        }
        default:
            break;
    }
    [cell.contactType setTitle:result forState:UIControlStateNormal];

    [pickerView removeFromSuperview];
    self.pickerIsShow = NO;
}


#pragma mark - Contact picker delegate methods


- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact {
    PBVCard *pbvCard = [[PBVCard alloc] init];
    NSMutableString *name = [NSMutableString string];
    if (contact.givenName && ![contact.givenName isEqualToString:@""]) {
        [name appendString:contact.givenName];
    }
    if (contact.middleName && ![contact.middleName isEqualToString:@""]) {
        [name appendFormat:@" %@", contact.middleName];
    }
    if (contact.familyName && ![contact.familyName isEqualToString:@""]) {
        [name appendFormat:@" %@", contact.familyName];
    }
    pbvCard.fullName = name;
    pbvCard.phone = [[contact.phoneNumbers.firstObject value] stringValue];
    pbvCard.email = [contact.emailAddresses.firstObject value];
    pbvCard.personImage = contact.thumbnailImageData;
    NSError *error = nil;
    pbvCard.vCardData = [[NSString alloc] initWithData:[CNContactVCardSerialization dataWithContacts:@[contact] error:&error] encoding:NSUTF8StringEncoding];

    [self.vCards addObject:pbvCard];
    [self.tableView reloadData];
}


- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person {
    PBVCard *pbvCard = [[PBVCard alloc] init];
    NSString *firstName;
    NSString *middleName;
    NSString *lastName;
    NSString *phoneNumber;
    NSString *emailString;
    NSData *retrievedImage = nil;

    // get the first name
    firstName = (__bridge_transfer NSString *) ABRecordCopyValue(person, kABPersonFirstNameProperty);

    //get the middle name
    middleName = (__bridge_transfer NSString *) ABRecordCopyValue(person, kABPersonMiddleNameProperty);

    // get the last name
    lastName = (__bridge_transfer NSString *) ABRecordCopyValue(person, kABPersonLastNameProperty);

    // get personPicture
    if (person != nil && ABPersonHasImageData(person)) {
        retrievedImage = (__bridge_transfer NSData *) ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
    }

    ABMultiValueRef phone = (ABMultiValueRef) ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFStringRef phoneID = ABMultiValueCopyValueAtIndex(phone, 0);
    phoneNumber = (__bridge_transfer NSString *) phoneID;
    CFRelease(phoneID);
    CFRelease(phone);

    ABMultiValueRef email = (ABMultiValueRef) ABRecordCopyValue(person, kABPersonEmailProperty);
    CFStringRef emailID = ABMultiValueCopyValueAtIndex(email, 0);
    emailString = (__bridge_transfer NSString *) emailID;
    CFRelease(emailID);
    CFRelease(email);

    NSMutableString *name = [NSMutableString string];
    if (firstName && ![firstName isEqualToString:@""]) {
        [name appendString:firstName];
    }
    if (middleName && ![middleName isEqualToString:@""]) {
        [name appendFormat:@" %@", middleName];
    }
    if (lastName && ![lastName isEqualToString:@""]) {
        [name appendFormat:@" %@", lastName];
    }

    pbvCard.fullName = name;
    pbvCard.phone = phoneNumber;
    pbvCard.email = emailString;
    pbvCard.personImage = retrievedImage;
    pbvCard.vCardData = [[NSString alloc] initWithData:(__bridge_transfer NSData *) ABPersonCreateVCardRepresentationWithPeople(person) encoding:NSUTF8StringEncoding];

    [self.vCards addObject:pbvCard];
    [self.tableView reloadData];
}


#pragma mark - Helper methods


- (void)setWarningOnRow:(NSIndexPath *)indexPath {
    [self.nonValidatedRows addObject:indexPath];
    switch (indexPath.section) {
        case NewCardSectionsTextSection: {
            PBCardTextTableViewCell *cell = (PBCardTextTableViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:NewCardSectionsTextSection]];
            [self setWarningOnTextField:cell.cardText];
            break;
        }
        case NewCardSectionsPhonesSection:
        case NewCardSectionsEmailsSection:
        case NewCardSectionsUrlsSection: {
            PBCardContactTableViewCell *cell = (PBCardContactTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
            [self setWarningOnTextField:cell.contact];
            break;
        }
        default:
            break;
    }
}


- (void)clearWarningOnRow:(NSIndexPath *)indexPath {
    if ([self.nonValidatedRows containsObject:indexPath]) {
        [self.nonValidatedRows removeObject:indexPath];
        switch (indexPath.section) {
            case NewCardSectionsTextSection: {
                PBCardTextTableViewCell *cell = (PBCardTextTableViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:NewCardSectionsTextSection]];
                [self clearWarningOnTextField:cell.cardText];
                break;
            }
            case NewCardSectionsPhonesSection:
            case NewCardSectionsEmailsSection:
            case NewCardSectionsUrlsSection: {
                PBCardContactTableViewCell *cell = (PBCardContactTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
                [self clearWarningOnTextField:cell.contact];
                break;
            }
            default:
                break;
        }
    }
}


- (void)setWarningOnTextField:(UITextField *)textField {
    textField.layer.masksToBounds = YES;
    textField.layer.borderColor = [[UIColor redColor] CGColor];
    textField.layer.borderWidth = 1.0f;
}


- (void)clearWarningOnTextField:(UITextField *)textField {
    textField.layer.borderColor = [[UIColor clearColor] CGColor];
}


- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.selectedTextField resignFirstResponder];
}


- (void)chooseImage:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:nil];
}


- (void)openSelector:(id)sender {
    if(self.pickerIsShow){
        return;
    }
    self.pickerIsShow = YES;
    UIPickerView *pickerView = [[UIPickerView alloc] init];
    [pickerView setFrame:CGRectMake(pickerView.frame.origin.x, pickerView.frame.origin.y, self.view.frame.size.width, pickerView.frame.size.height)];
    pickerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    pickerView.dataSource = self;
    pickerView.delegate = self;

    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    self.selectedRow = indexPath;
    switch (indexPath.section) {
        case NewCardSectionsPhonesSection: {
            pickerView.tag = 100;
            PBCardPhone *phone = self.phones[(NSUInteger) indexPath.row];
            [pickerView selectRow:(phone.phoneType - 101) inComponent:0 animated:NO];
            break;
        }
        case NewCardSectionsEmailsSection: {
            pickerView.tag = 200;
            PBCardEmail *email = self.emails[(NSUInteger) indexPath.row];
            [pickerView selectRow:(email.emailType - 201) inComponent:0 animated:NO];
            break;
        }
        case NewCardSectionsUrlsSection: {
            pickerView.tag = 300;
            PBCardURL *url = self.urls[(NSUInteger) indexPath.row];
            [pickerView selectRow:(url.urlType - 301) inComponent:0 animated:NO];
            break;
        }
        default:
            break;
    }

    [self.view addSubview:pickerView];
}


- (void)addItemFromHeader:(id)sender {
    switch (((UIButton *) sender).tag) {
        case NewCardSectionsVCardSection: {
            [self showVCardAction];
            break;
        }
        case NewCardSectionsBeaconsSection: {
            PBLinkBeaconViewController *linkBeaconViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PBLinkBeaconViewController"];
            linkBeaconViewController.delegate = self;
            linkBeaconViewController.selectedBeacons = self.linkedBeacons;
            [self.navigationController pushViewController:linkBeaconViewController animated:YES];
            break;
        }
        case NewCardSectionsShareSection: {
            [self showShareViewController];
            break;
        }
        default:
            break;
    }

}


- (void)showShareViewController {
    PBShareCardViewController *shareCardViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PBShareCardViewController"];
    shareCardViewController.delegate = self;
    self.navigationController.definesPresentationContext = YES;
    shareCardViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    shareCardViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self.tabBarController presentViewController:shareCardViewController animated:YES completion:nil];
}


- (void)addItem:(id)sender {
    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    switch (indexPath.section) {
        case NewCardSectionsPhonesSection: {
            PBCardPhone *phone = [[PBCardPhone alloc] init];
            phone.phoneType = PBPhoneTypeMobile;
            [self.phones addObject:phone];
            break;
        }
        case NewCardSectionsEmailsSection: {
            PBCardEmail *email = [[PBCardEmail alloc] init];
            email.emailType = PBEmailTypePersonal;
            [self.emails addObject:email];
            break;
        }
        case NewCardSectionsUrlsSection: {
            PBCardURL *url = [[PBCardURL alloc] init];
            url.urlType = PBUrlWebsite;
            [self.urls addObject:url];
            break;
        }
        default:
            break;
    }
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}


- (void)removeItem:(id)sender {
    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    switch (indexPath.section) {
        case NewCardSectionsPhonesSection: {
            [self.phones removeObjectAtIndex:(NSUInteger) indexPath.row];
            break;
        }
        case NewCardSectionsEmailsSection: {
            [self.emails removeObjectAtIndex:(NSUInteger) indexPath.row];
            break;
        }
        case NewCardSectionsUrlsSection: {
            [self.urls removeObjectAtIndex:(NSUInteger) indexPath.row];
            break;
        }
        default:
            break;
    }
    if ([self.nonValidatedRows containsObject:indexPath]) {
        [self.nonValidatedRows removeObject:indexPath];
    }
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)showVCardAction {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *addNewAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add New Using Form", @"Add New Using Form") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        PBAddVCardViewController *addVCardViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PBAddVCardViewController"];
        addVCardViewController.delegate = self;
        [self.navigationController pushViewController:addVCardViewController animated:YES];
    }];
    UIAlertAction *loadFromContactsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Import From Device Contacts", @"Import From Device Contacts") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSOperatingSystemVersion systemVersion;
        systemVersion.majorVersion = 9;
        systemVersion.minorVersion = 0;
        systemVersion.patchVersion = 0;
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:systemVersion]) {
            CNContactPickerViewController *contactPickerViewController = [[CNContactPickerViewController alloc] init];
            contactPickerViewController.delegate = self;
            [self presentViewController:contactPickerViewController animated:YES completion:nil];
        }
        else {
            ABPeoplePickerNavigationController *peoplePickerNavigationController = [[ABPeoplePickerNavigationController alloc] init];
            peoplePickerNavigationController.delegate = self;
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:addNewAction];
    [alertController addAction:loadFromContactsAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (IBAction)cancelAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)saveAction:(id)sender {
    [self.selectedTextField resignFirstResponder];
    if (self.nonValidatedRows.count == 0 && ![NSString isEmptyOrNil:self.card.title]) {
        if ([NSString isEmptyOrNil:self.card.cardId]) {
            self.card.cardId = [GUID createGUID];
        }
        self.card.phones = self.phones;
        self.card.emails = self.emails;
        self.card.urls = self.urls;
        self.card.cardShare = self.shareContacts;
        self.card.vCards = self.vCards;
        self.card.beacons = self.linkedBeacons;
        [self.delegate sender:self passData:self.card];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        if ([NSString isEmptyOrNil:self.card.title]) {
            PBCardTextTableViewCell *cell = (PBCardTextTableViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:NewCardSectionsTextSection]];
            [self setWarningOnTextField:cell.cardText];
        }
        NSError *error = [NSError errorWithDomain:kPBErrorDomain code:kPBUIErrorDataIsNotValidCode userInfo:@{NSLocalizedDescriptionKey : kPBUIErrorDataIsNotValid}];
        [self showAlertError:error];
    }

}


- (IBAction)linkOffAction:(id)sender {
    if (self.selectedRow) {
        PBBeaconTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.selectedRow];
        [cell setEnabled:NO];
        PBBeacon *beacon = self.linkedBeacons[(NSUInteger) self.selectedRow.row];
        beacon.state = NO;
        if (beacon.state) {
            self.linkOffButton.enabled = YES;
            self.linkOnButton.enabled = NO;
        }
        else {
            self.linkOffButton.enabled = NO;
            self.linkOnButton.enabled = YES;
        }
    }
}


- (IBAction)linkOnAction:(id)sender {
    if (self.selectedRow) {
        PBBeaconTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.selectedRow];
        [cell setEnabled:YES];
        PBBeacon *beacon = self.linkedBeacons[(NSUInteger) self.selectedRow.row];
        beacon.state = YES;
        if (beacon.state) {
            self.linkOffButton.enabled = YES;
            self.linkOnButton.enabled = NO;
        }
        else {
            self.linkOffButton.enabled = NO;
            self.linkOnButton.enabled = YES;
        }
    }
}


- (IBAction)shareChangeAction:(id)sender {
    if (self.selectedRow) {
        PBCardsShare *cardsShare = self.shareContacts[(NSUInteger) self.selectedRow.row];
        PBShareCardViewController *shareCardViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PBShareCardViewController"];
        shareCardViewController.delegate = self;
        shareCardViewController.cardsShare = cardsShare;
        shareCardViewController.index = self.selectedRow.row;
        self.navigationController.definesPresentationContext = YES;
        shareCardViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        shareCardViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [self.tabBarController presentViewController:shareCardViewController animated:YES completion:nil];
    }
}


- (IBAction)deleteAction:(id)sender {
    if (self.selectedRow) {
        switch (self.selectedRow.section) {
            case NewCardSectionsVCardSection: {
                [self.vCards removeObjectAtIndex:(NSUInteger) self.selectedRow.row];
                break;
            }
            case NewCardSectionsBeaconsSection: {
                [self.linkedBeacons removeObjectAtIndex:(NSUInteger) self.selectedRow.row];
                break;
            }
            case NewCardSectionsShareSection: {
                [self.shareContacts removeObjectAtIndex:(NSUInteger) self.selectedRow.row];
                break;
            }
            default:
                break;
        }
        [self.tableView reloadData];
        [self tableView:self.tableView didDeselectRowAtIndexPath:self.selectedRow];
    }
}


- (IBAction)vCardChangeAction:(id)sender {
    if (self.selectedRow) {
        PBVCard *vCard = self.vCards[(NSUInteger) self.selectedRow.row];
        PBAddVCardViewController *addVCardViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PBAddVCardViewController"];
        addVCardViewController.delegate = self;
        addVCardViewController.vCard = vCard;
        addVCardViewController.index = self.selectedRow.row;
        [self.navigationController pushViewController:addVCardViewController animated:YES];
    }
}


#pragma mark - Pass data delegate methods


- (void)sender:(id)sender passData:(id)data {
    if ([sender isMemberOfClass:[PBShareCardViewController class]]) {
        NSInteger index = ((PBShareCardViewController *) sender).index;
        PBCardsShare *cardsShare = data;
        if (self.shareContacts.count > index && index != -1) {
            self.shareContacts[(NSUInteger) index] = cardsShare;
        }
        else {
            [self.shareContacts addObject:cardsShare];
        }
    }
    if ([sender isMemberOfClass:[PBLinkBeaconViewController class]]) {
        NSArray *beacons = data;
        self.linkedBeacons = [beacons mutableCopy];
    }
    if ([sender isMemberOfClass:[PBAddVCardViewController class]]) {
        NSInteger index = ((PBAddVCardViewController *) sender).index;
        PBVCard *vCard = data;
        if (self.vCards.count > index && index != -1) {
            self.vCards[(NSUInteger) index] = vCard;
        }
        else {
            [self.vCards addObject:vCard];
        }
    }
    [self.tableView reloadData];
}

@end
