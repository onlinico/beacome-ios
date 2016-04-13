//
//  PBLinkBeaconViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/12/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBLinkBeaconViewController.h"
#import "PBApplicationFacade.h"
#import "PBBeaconLinkTableViewCell.h"
#import "PBPassDataDelegate.h"
#import "PBAddBeaconViewController.h"
#import "Constants.h"
#import "PBError.h"


@interface PBLinkBeaconViewController () <UITableViewDelegate, UITableViewDataSource, PBApplicationFacadeDelegate, PBPassDataDelegate>


@property (nonatomic, strong) PBApplicationFacade *facade;
@property (nonatomic, strong) NSMutableArray *beacons;
@end


@implementation PBLinkBeaconViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.facade = [PBApplicationFacade sharedManager];

    if (!self.selectedBeacons) {
        self.selectedBeacons = [NSMutableArray array];
    }

    self.facade.delegate = self;
    [self loadBeacons];
    // Do any additional setup after loading the view.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.facade.delegate = self;
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.facade.delegate = nil;
}


#pragma mark - Table view datasource methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.beacons.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PBBeaconLinkTableViewCell *cell = (PBBeaconLinkTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"BeaconLinkTableCellIdentifier"];

    PBBeacon *beacon = nil;
    if (self.beacons && self.beacons.count > indexPath.row) {
        beacon = self.beacons[(NSUInteger) indexPath.row];
    }
    if (beacon) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            cell.beaconUid.text = beacon.beaconUid;
            cell.linkedCardsCount.text = [NSString stringWithFormat:@"%ld", (long) beacon.linkedCardsCount];
            if ([self.selectedBeacons containsObject:beacon]) {
                cell.selected = YES;
            }
            else{
                cell.selected = NO;
            }
            [cell.selectButton addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventTouchUpInside];
        });
    }
    [cell setNeedsLayout];

    return cell;
}


- (void)selectItem:(id)sender {
    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    if (!((UIButton *) sender).selected) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
    else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self tableView:self.tableView didDeselectRowAtIndexPath:indexPath];
    }
}


#pragma mark - Table view delegate methods


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PBBeacon *beacon = nil;
    if (self.beacons && self.beacons.count > indexPath.row) {
        beacon = self.beacons[(NSUInteger) indexPath.row];
    }
    if (beacon) {
        beacon.state = YES;
        [self.selectedBeacons addObject:beacon];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.selected = YES;
    }
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    PBBeacon *beacon = nil;
    if (self.beacons && self.beacons.count > indexPath.row) {
        beacon = self.beacons[(NSUInteger) indexPath.row];
    }
    if (beacon && [self.selectedBeacons containsObject:beacon]) {
        [self.selectedBeacons removeObject:beacon];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.selected = NO;
    }
}


#pragma mark - Application facade delegate


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedUserBeacons:(NSArray *)beacons {
    [self updateBeacons:beacons];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:[PBError checkAndCreateInApplicationError:error]];
}


#pragma mark - Navigation


// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"LinkBeaconSegue"]) {
//        ((PBCard *) self.card).beacons = self.selectedBeacons;
//        ((PBCard *) self.card).beaconsCount = self.selectedBeacons.count;
//    }
//    if ([segue.identifier isEqualToString:@"AddNewBeaconSegue"]) {
//        ((PBAddBeaconViewController *) segue.destinationViewController).delegate = self;
//    }
//}


#pragma mark - Helper methods


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)loadBeacons {
    [self.facade loadUserBeaconsWithCallback:^(NSArray *results) {
        [self updateBeacons:results];
    }];
}


- (void)updateBeacons:(NSArray *)beacons {
    self.beacons = [[beacons sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self.beaconUid" ascending:YES]]] mutableCopy];
    [self.selectedBeacons enumerateObjectsUsingBlock:^(PBBeacon *selectedBeacon, NSUInteger index, BOOL *stop){
        [beacons enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index1, BOOL *stop1){
            if([selectedBeacon isEqual:beacon]){
                selectedBeacon.cards = beacon.cards;
                *stop1 = YES;
            }
        }];
    }];
    [self.tableView reloadData];
}


- (IBAction)cancelAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)linkAction:(id)sender {
    [self.selectedBeacons enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop){
        beacon.state = YES;
    }];
    [self.delegate sender:self passData:self.selectedBeacons];
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)addAction:(id)sender {
    PBAddBeaconViewController *addBeaconViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PBAddBeaconViewController"];
    addBeaconViewController.delegate = self;

    [self.navigationController pushViewController:addBeaconViewController animated:YES];
}


#pragma mark - Pass data delegate methods


- (void)sender:(id)sender passData:(id)data {
    if ([sender isMemberOfClass:[PBAddBeaconViewController class]]) {
        [self.beacons addObject:data];
        [self.tableView reloadData];
    }
}

@end
