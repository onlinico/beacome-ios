//
//  PBCardDetailViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/24/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>
#import <ContactsUI/ContactsUI.h>
#import "PBCardDetailViewController.h"
#import "PBMainInfoTableViewCell.h"
#import "PBDetailInfoTableViewCell.h"
#import "PBContactTableViewCell.h"
#import "PBVCardTableViewCell.h"
#import "PBCard.h"
#import "NSString+Enum.h"
#import "PBvCard.h"
#import "PBLabel.h"
#import "PBApplicationFacade.h"
#import "Constants.h"
#import "PBError.h"
#import "PBMapViewController.h"


typedef NS_ENUM(NSUInteger, CardSections) {
    CardSectionsInfoSection,
    CardSectionsContactsSection,
    CardSectionsPeoplesSection,
    CardSectionsMapSection
};


@interface PBCardDetailViewController () <UITableViewDataSource, UITableViewDelegate, PBApplicationFacadeDelegate, TTTAttributedLabelDelegate, CNContactViewControllerDelegate, ABNewPersonViewControllerDelegate>


@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, strong) PBApplicationFacade *facade;

@end


@implementation PBCardDetailViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.contacts = [NSMutableArray array];
    self.facade = [PBApplicationFacade sharedManager];
    self.facade.delegate = self;
    if (self.card) {
        self.title = self.card.title;
        [self configureCard];
        [self.facade loadDetailForInfoCard:self.card callback:^(PBCard *cardDetail) {
            self.card.title = cardDetail.title;
            self.card.summary = cardDetail.summary;
            self.card.logo = cardDetail.logo;
            self.card.phones = cardDetail.phones;
            self.card.emails = cardDetail.emails;
            self.card.urls = cardDetail.urls;
            self.card.vCards = cardDetail.vCards;
            self.card.isFavourite = cardDetail.isFavourite;
            self.title = self.card.title;
            [self configureCard];
            [self.tableView reloadData];
        }];
    }
    // Do any additional setup after loading the view.
}


- (void)configureCard {
    [self.contacts removeAllObjects];
    [self.contacts addObjectsFromArray:self.card.phones];
    [self.contacts addObjectsFromArray:self.card.emails];
    [self.contacts addObjectsFromArray:self.card.urls];

    [self setFavoriteButtonState:self.card.isFavourite];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.facade.delegate = self;
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.facade.delegate = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"ShowMapSegue"]){
        ((PBMapViewController *)segue.destinationViewController).latitude = self.card.latitude;
        ((PBMapViewController *)segue.destinationViewController).longitude = self.card.longitude;
        ((PBMapViewController *)segue.destinationViewController).distance = self.card.distance;
        ((PBMapViewController *)segue.destinationViewController).cardTitle = self.card.title;
    }
}


#pragma mark - Table view datasource and delegate methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.card.latitude > 0 && self.card.longitude > 0 && self.card.distance > 0) {
        return 4;
    }
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case CardSectionsInfoSection: {
            return 2;
        }
        case CardSectionsContactsSection: {
            return self.contacts.count;
        }
        case CardSectionsPeoplesSection: {
            return self.card.vCards.count;
        }
        case CardSectionsMapSection: {
            return 1;
        }
        default:
            break;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case CardSectionsInfoSection: {
            if (indexPath.row == 0) {
                cell = (PBMainInfoTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"MainInfoCellIdentifier"];
                if (self.card) {
                    ((PBMainInfoTableViewCell *) cell).cardTitle.text = self.card.title;
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        ((PBMainInfoTableViewCell *) cell).cardImage.image = self.card.logo ? [UIImage imageWithData:self.card.logo] : [UIImage imageNamed:@"card_default_icon"];
                        ((PBMainInfoTableViewCell *) cell).cardImage.layer.cornerRadius = ((PBMainInfoTableViewCell *) cell).cardImage.frame.size.width / 2;
                        ((PBMainInfoTableViewCell *) cell).cardImage.clipsToBounds = YES;
                    });
                }
            }
            else if (indexPath.row == 1) {
                cell = (PBDetailInfoTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"DetailCellIdentifier"];
                if (self.card) {
                    ((PBDetailInfoTableViewCell *) cell).cardDetail.text = self.card.summary;
                }
            }
            break;
        }
        case CardSectionsContactsSection: {
            cell = (PBContactTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"ContactCellIdentifier"];
//            ((PBContactTableViewCell *)cell).contactValue.textContainerInset = UIEdgeInsetsZero;
            TTTAttributedLabel *label = (TTTAttributedLabel *) ((PBContactTableViewCell *) cell).contactValue;
            label.enabledTextCheckingTypes = NSTextCheckingAllTypes;
            label.linkAttributes = @{NSUnderlineStyleAttributeName : @(0), NSForegroundColorAttributeName : kLinkDetectionTextColor};
            label.delegate = self;
            if (self.contacts.count > indexPath.row) {
                id contact = self.contacts[(NSUInteger) indexPath.row];
                if ([contact isMemberOfClass:[PBCardPhone class]]) {
                    ((PBContactTableViewCell *) cell).contactType.text = [NSString stringFromPhoneType:((PBCardPhone *) contact).phoneType];
                    ((PBContactTableViewCell *) cell).contactValue.text = ((PBCardPhone *) contact).phoneNumber;
                }
                else if ([contact isMemberOfClass:[PBCardEmail class]]) {
                    ((PBContactTableViewCell *) cell).contactType.text = [NSString stringFromEmailType:((PBCardEmail *) contact).emailType];
                    ((PBContactTableViewCell *) cell).contactValue.text = ((PBCardEmail *) contact).email;
                }
                else if ([contact isMemberOfClass:[PBCardURL class]]) {
                    ((PBContactTableViewCell *) cell).contactType.text = [NSString stringFromUrlType:((PBCardURL *) contact).urlType];
                    ((PBContactTableViewCell *) cell).contactValue.text = ((PBCardURL *) contact).url;
                }
            }
            break;
        }
        case CardSectionsPeoplesSection: {
            cell = (PBVCardTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"VCardCellIdentifier"];
            if (self.card.vCards.count > indexPath.row) {
                PBVCard *vCard = self.card.vCards[(NSUInteger) indexPath.row];
                ((PBVCardTableViewCell *) cell).vCardFullName.text = vCard.fullName;
                ((PBVCardTableViewCell *) cell).vCardEmail.text = vCard.email;
                ((PBVCardTableViewCell *) cell).vCardPhone.text = vCard.phone;
                dispatch_async(dispatch_get_main_queue(), ^{
                    ((PBVCardTableViewCell *) cell).vCardImage.image = vCard.personImage ? [UIImage imageWithData:vCard.personImage] : [UIImage imageNamed:@"user_default_icon"];
                    ((PBVCardTableViewCell *) cell).vCardImage.layer.cornerRadius = ((PBVCardTableViewCell *) cell).vCardImage.frame.size.width / 2;
                    ((PBVCardTableViewCell *) cell).vCardImage.clipsToBounds = YES;
                });
                MGSwipeButton *importContact = [MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"import_icon"] backgroundColor:kSwipeCellButtonColor callback:^BOOL(MGSwipeTableCell *sender) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Import contact", @"Import contact") message:NSLocalizedString(@"Do you want to import contact into your contacts", @"Do you want to import contact into your contacts") preferredStyle:UIAlertControllerStyleActionSheet];
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [vCard importVCardIntoNativeContactsWithCallback:^(id contact) {
                            if (!contact) {
                                NSError *error = [NSError errorWithDomain:kPBErrorDomain code:kPBServiceErrorCantImportVCardCode userInfo:@{NSLocalizedDescriptionKey : kPBServiceErrorCantImportVCard}];
                                [self showAlertError:error];
                            }
                            else {
                                NSOperatingSystemVersion systemVersion;
                                systemVersion.majorVersion = 9;
                                systemVersion.minorVersion = 0;
                                systemVersion.patchVersion = 0;
                                if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:systemVersion]) {
                                    CNContactStore *store = [[CNContactStore alloc] init];
                                    CNContactViewController *controller = [CNContactViewController viewControllerForNewContact:contact];
                                    controller.contactStore = store;
                                    controller.delegate = self;
                                    [self.navigationController pushViewController:controller animated:YES];
                                }
                                else {
                                    ABNewPersonViewController *controller = [[ABNewPersonViewController alloc] init];
                                    controller.displayedPerson = CFBridgingRetain(contact);
                                    controller.newPersonViewDelegate = self;
                                    [self.navigationController pushViewController:controller animated:YES];
                                }

                            }
                        }];
                    }]];
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No") style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alertController animated:YES completion:nil];
                    return YES;
                }];
                importContact.tintColor = [UIColor whiteColor];
                ((PBVCardTableViewCell *) cell).rightButtons = @[importContact];
            }
            break;
        }
        case CardSectionsMapSection: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MapCellIdentifier"];
            cell.textLabel.text = NSLocalizedString(@"Show on map", @"Show on map");
            cell.textLabel.textColor = kLinkDetectionTextColor;
        }
        default:
            break;
    }
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case CardSectionsInfoSection: {
            if (indexPath.row == 0) {
                return 130.0;
            }
            else if (indexPath.row == 1) {
                return UITableViewAutomaticDimension;
            }
        }
        case CardSectionsContactsSection: {
            return 44.0;
        }
        case CardSectionsPeoplesSection: {
            return 100.0;
        }
        default:
            break;
    }
    return 44.0;
}


- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case CardSectionsInfoSection: {
            if (indexPath.row == 0) {
                return 130.0;
            }
            else if (indexPath.row == 1) {
                return 44.0;
            }
        }
        case CardSectionsContactsSection: {
            return 44.0;
        }
        case CardSectionsPeoplesSection: {
            return 100.0;
        }
        default:
            break;
    }
    return 44.0;
}


#pragma mark - Actions


- (IBAction)favoriteAction:(id)sender {
    __weak PBCardDetailViewController *weakSelf = self;
    self.card.isFavourite = !self.card.isFavourite;
    [self setFavoriteButtonState:self.card.isFavourite];
    [self.facade setCard:self.card favorite:self.card.isFavourite callback:^(BOOL result) {
        if (!result) {
            [weakSelf setFavoriteButtonState:weakSelf.card.isFavourite];
        }
    }];
}


#pragma mark - Application facade delegate methods


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:[PBError checkAndCreateInApplicationError:error]];
}


#pragma mark TTTAttributedLabel delegate methods


- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}


- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phoneNumber]]];
}

#pragma mark - Contacts delegate methods

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(CNContact *)contact {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Helper methods


- (void)setFavoriteButtonState:(BOOL)state {
    if (state) {
        [self.favoriteButton setImage:[UIImage imageNamed:@"favorite_button_active"]];
    }
    else {
        [self.favoriteButton setImage:[UIImage imageNamed:@"favorite_button_inactive"]];
    }
}


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
