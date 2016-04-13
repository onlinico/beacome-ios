//
//  PBBeaconDetailViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/8/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBBeaconDetailViewController.h"
#import "PBBeacon.h"
#import "PBDeviceAsBeaconTableHeaderView.h"
#import "PBCardSectionHeaderView.h"
#import "PBApplicationFacade.h"
#import "PBLinkMyCardsViewController.h"
#import "PBPassDataDelegate.h"
#import "PBBwaconUIDTableViewCell.h"
#import "PBMyCardTableViewCell.h"
#import "NSString+Enum.h"
#import "Constants.h"
#import "PBBeaconCard.h"
#import "PBError.h"


typedef NS_ENUM(NSUInteger, BeaconSections) {
    BeaconSectionsDeviceAsBeaconSection,
//    BeaconSectionsBeaconInfoSection,
            BeaconSectionsLinkedCardsSection
};


@interface PBBeaconDetailViewController () <UITableViewDataSource, UITableViewDelegate, PBPassDataDelegate, PBApplicationFacadeDelegate>


@property (nonatomic, strong) PBApplicationFacade *facade;
@property (nonatomic, strong) NSMutableArray *cards;
@property (nonatomic, strong) NSIndexPath *selectedRow;
@property (nonatomic, assign) BOOL deviceAsBeaconAdded;

@end


@implementation PBBeaconDetailViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.facade = [PBApplicationFacade sharedManager];
    self.facade.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    if (self.deviceAsBeacon) {
        self.beacon = [self.facade getDeviceAsBeaconInfo];
        [self.facade getBeaconByUid:((PBBeacon *) self.beacon).beaconUid callback:^(PBBeacon *beacon) {
            if (beacon) {
                self.beacon = beacon;
                [self.facade getLinkedCardsForBeacon:self.beacon callback:^(NSArray *cards) {
                    self.deviceAsBeaconAdded = YES;
                    self.cards = [[cards sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self.title" ascending:YES]]] mutableCopy];
                    [self.tableView reloadData];
                }];
            }

        }];
    }
    else {
        if (self.beacon) {
            [self.facade getLinkedCardsForBeacon:self.beacon callback:^(NSArray *cards) {
                self.cards = [[cards sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self.title" ascending:YES]]] mutableCopy];
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [self.tableView reloadData];
                });
            }];
        }
        else {
            self.cards = [NSMutableArray array];
        }
    }

    self.actionsToolbar.tintColor = [UIColor lightGrayColor];
    self.linkOffButton.enabled = NO;
    self.linkOnButton.enabled = NO;
    self.deleteButton.enabled = NO;

    [self.tableView registerNib:[UINib nibWithNibName:@"PBCardSectionHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"PBCardSectionHeaderView"];
    [self.tableView registerNib:[UINib nibWithNibName:@"PBDeviceAsBeaconTableHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"PBDeviceAsBeaconTableHeaderView"];
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
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


#pragma mark - Table view datasource and delegate methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 3;
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            return 1;
        }
//        case 1: {
//            return 3;
//        }
//        case 2: {
//            return self.cards.count;
//        }
        case 1: {
            return self.cards.count;
        }
        default:
            break;
    }
    return 0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case BeaconSectionsDeviceAsBeaconSection: {
            return 44.0;
        }
//        case BeaconSectionsBeaconInfoSection: {
//            return 28.0;
//        }
        case BeaconSectionsLinkedCardsSection: {
            return 62.0;
        }
        default:
            break;
    }
    return 0;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = nil;
    switch (section) {
        case BeaconSectionsDeviceAsBeaconSection: {
            if (self.deviceAsBeacon) {
                PBDeviceAsBeaconTableHeaderView *header = (id) [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"PBDeviceAsBeaconTableHeaderView"];
                header.publisherSwitch.on = self.facade.isPublishing;
                [header.publisherSwitch addTarget:self action:@selector(publisherSwitchChangeValue:) forControlEvents:UIControlEventValueChanged];
                headerView = header;
            }
            break;
        }
//        case BeaconSectionsBeaconInfoSection: {
//            break;
//        }
        case BeaconSectionsLinkedCardsSection: {
            PBCardSectionHeaderView *header = (id) [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"PBCardSectionHeaderView"];
            [header.addButton addTarget:self action:@selector(addItemFromHeader:) forControlEvents:UIControlEventTouchUpInside];
            header.headerTitle.text = NSLocalizedString(@"Cards", @"Cards");
            headerView = header;
            break;
        }
        default:
            break;
    }

    return headerView;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case BeaconSectionsDeviceAsBeaconSection: {
            return 44;
        }
//        case BeaconSectionsBeaconInfoSection: {
//            return 44;
//        }
        case BeaconSectionsLinkedCardsSection: {
            return 100;
        }

        default:
            break;
    }
    return 44;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case BeaconSectionsDeviceAsBeaconSection: {
            cell = (PBBwaconUIDTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"BeaconUIDTableViewCellIdentifier"];
            ((PBBwaconUIDTableViewCell *) cell).beaconUid.text = ((PBBeacon *) self.beacon).beaconUid;
            break;
        }
            /*case BeaconSectionsBeaconInfoSection: {
                cell = (PBBeaconInfoTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"BeaconInfoTableViewIdentifier"];
                switch (indexPath.row) {
                    case 0: {
                        ((PBBeaconInfoTableViewCell *) cell).infoLabel.text = @"Major";
                        ((PBBeaconInfoTableViewCell *) cell).infoValue.text = [NSString stringWithFormat:@"%ld", (long) ((PBBeacon *) self.beacon).major];
                        break;
                    }
                    case 1: {
                        ((PBBeaconInfoTableViewCell *) cell).infoLabel.text = @"Minor";
                        ((PBBeaconInfoTableViewCell *) cell).infoValue.text = [NSString stringWithFormat:@"%ld", (long) ((PBBeacon *) self.beacon).minor];
                        break;
                    }
                    case 2: {
                        ((PBBeaconInfoTableViewCell *) cell).infoLabel.text = @"Power Level";
                        ((PBBeaconInfoTableViewCell *) cell).infoValue.text = [NSString stringWithFormat:@"%ld", (long) ((PBBeacon *) self.beacon).power];
                        break;
                    }
                    default:
                        break;
                }
                break;
            }*/
        case BeaconSectionsLinkedCardsSection: {
            cell = (PBMyCardTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"CardTableViewCellIdentifier"];
            PBCard *card = nil;
            if (self.cards && self.cards.count > indexPath.row) {
                card = self.cards[(NSUInteger) indexPath.row];
            }
            if (card) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ((PBMyCardTableViewCell *) cell).cardImage.image = card.logo ? [UIImage imageWithData:card.logo] : [UIImage imageNamed:@"card_default_icon"];
                    ((PBMyCardTableViewCell *) cell).cardImage.layer.cornerRadius = ((PBMyCardTableViewCell *) cell).cardImage.frame.size.width / 2;
                    ((PBMyCardTableViewCell *) cell).cardImage.clipsToBounds = YES;
                    [((PBMyCardTableViewCell *) cell) setEnabled:card.isActive];
                });

                ((PBMyCardTableViewCell *) cell).cardTitle.text = card.title;
                ((PBMyCardTableViewCell *) cell).cardDescription.text = card.summary;
                ((PBMyCardTableViewCell *) cell).cardPermission.text = [NSString stringFromCardPermission:card.permission];
                ((PBMyCardTableViewCell *) cell).linkedBeaconsCount.text = [NSString stringWithFormat:@"%ld", (long) card.beaconsCount];
            }
            [cell setNeedsLayout];
            break;
        }
        default:
            break;
    }
    return cell;
}


#pragma mark - Table view delegate methods


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedRow = indexPath;
    switch (indexPath.section) {
        case BeaconSectionsLinkedCardsSection: {
            self.actionsToolbar.tintColor = kToolbarActiveTintColor;
            self.deleteButton.enabled = YES;
            PBCard *card = self.cards[(NSUInteger) self.selectedRow.row];
            if(card.isActive){
                self.linkOffButton.enabled = YES;
                self.linkOnButton.enabled = NO;
            }
            else{
                self.linkOnButton.enabled = YES;
                self.linkOffButton.enabled = NO;
            }
            break;
        }
        case BeaconSectionsDeviceAsBeaconSection:
//        case BeaconSectionsBeaconInfoSection:
        default: {
            self.actionsToolbar.tintColor = [UIColor lightGrayColor];
            self.linkOffButton.enabled = NO;
            self.linkOnButton.enabled = NO;
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
    self.deleteButton.enabled = NO;
}


#pragma mark - Actions


- (IBAction)linkOffAction:(id)sender {
    if (self.selectedRow) {
        PBMyCardTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.selectedRow];
        [cell setEnabled:NO];
        PBCard *card = self.cards[(NSUInteger) self.selectedRow.row];
        card.isActive = NO;
        if(card.isActive){
            self.linkOffButton.enabled = YES;
            self.linkOnButton.enabled = NO;
        }
        else{
            self.linkOnButton.enabled = YES;
            self.linkOffButton.enabled = NO;
        }
    }
}


- (IBAction)linkOnAction:(id)sender {
    if (self.selectedRow) {
        PBMyCardTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.selectedRow];
        [cell setEnabled:YES];
        PBCard *card = self.cards[(NSUInteger) self.selectedRow.row];
        card.isActive = YES;
        if(card.isActive){
            self.linkOffButton.enabled = YES;
            self.linkOnButton.enabled = NO;
        }
        else{
            self.linkOnButton.enabled = YES;
            self.linkOffButton.enabled = NO;
        }
    }
}


- (IBAction)deleteAction:(id)sender {
    [self.cards removeObjectAtIndex:(NSUInteger) self.selectedRow.row];
    [self.tableView reloadData];
}


- (IBAction)saveAction:(id)sender {
    __block NSMutableArray *linkedCards = [NSMutableArray array];
    [self.cards enumerateObjectsUsingBlock:^(PBCard *object, NSUInteger index, BOOL *stop) {
        PBBeaconCard *beaconCard = [[PBBeaconCard alloc] init];
        beaconCard.cardGuid = object.cardId;
        beaconCard.isActive = object.isActive;
        [linkedCards addObject:beaconCard];
    }];
    ((PBBeacon *) self.beacon).cards = linkedCards;
    if (self.deviceAsBeacon && !self.deviceAsBeaconAdded) {
        [self.facade addBeacon:self.beacon callback:nil];
    }
    else {
        [self.facade updateBeacon:self.beacon callback:nil];
    }
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Pass data delegate methods


- (void)sender:(id)sender passData:(id)data {
    if ([sender isMemberOfClass:[PBLinkMyCardsViewController class]]) {
        self.cards = data;
        [self.tableView reloadData];
    }
}


#pragma mark - Application facade delegate


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:[PBError checkAndCreateInApplicationError:error]];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailBluetoothServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:error];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveDetailCardInfo:(PBCard *)card {
    NSUInteger index = [self.cards indexOfObject:card];
    self.cards[index] = card;
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:BeaconSectionsLinkedCardsSection]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didUpdateBluetoothStatus:(BOOL)status {
    if (self.deviceAsBeacon) {
        PBDeviceAsBeaconTableHeaderView *deviceAsBeaconTableHeaderView = (PBDeviceAsBeaconTableHeaderView *) [self tableView:self.tableView viewForHeaderInSection:BeaconSectionsDeviceAsBeaconSection];
        deviceAsBeaconTableHeaderView.publisherSwitch.on = status;
    }
}


#pragma mark - Helper methods


- (void)addItemFromHeader:(id)sender {
    PBLinkMyCardsViewController *linkMyCardsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PBLinkMyCardsViewController"];
    linkMyCardsViewController.delegate = self;
    linkMyCardsViewController.selectedCards = self.cards;
    [self.navigationController pushViewController:linkMyCardsViewController animated:YES];
}


- (void)publisherSwitchChangeValue:(id)sender {
    UISwitch *uiSwitch = sender;
    if (uiSwitch.on) {
        uiSwitch.on = [self.facade startPublishing];
    }
    else {
        uiSwitch.on = [self.facade stopPublishing];
    }
}


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
