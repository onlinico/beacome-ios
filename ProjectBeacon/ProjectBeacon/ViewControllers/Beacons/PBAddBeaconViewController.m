//
//  PBAddBeaconViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/14/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBAddBeaconViewController.h"
#import "PBPassDataDelegate.h"
#import "PBBeacon.h"
#import "PBScannedBeaconTableViewCell.h"
#import "PBApplicationFacade.h"
#import "PBError.h"
#import "Constants.h"


@interface PBAddBeaconViewController () <UITableViewDataSource, UITableViewDelegate, PBApplicationFacadeDelegate>


@property (nonatomic, strong) PBBeacon *beacon;
@property (nonatomic, strong) NSArray *scannedBeacons;
@property (nonatomic, strong) PBApplicationFacade *facade;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSTimer *scanningTimer;

@end


@implementation PBAddBeaconViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    self.tableView.hidden = YES;

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.refreshControl.tintColor = [UIColor darkGrayColor];
    [self.refreshControl addTarget:self action:@selector(updateBeacons) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    self.scanningTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(scanningDidEnd) userInfo:nil repeats:NO];

    self.facade = [PBApplicationFacade sharedManager];


    // Do any additional setup after loading the view.
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.facade.delegate = self;
    [self updateBeacons];
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

#pragma mark - Table view datasource and delegate methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.scannedBeacons.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PBScannedBeaconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ScannedBeaconTableViewCell"];
    if (self.scannedBeacons && self.scannedBeacons.count > indexPath.row) {
        PBBeacon *beacon = self.scannedBeacons[(NSUInteger) indexPath.row];

        cell.beaconUUID.text = beacon.beaconUid;
        [cell.selectButton addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.scannedBeacons && self.scannedBeacons.count > indexPath.row) {
        self.beacon = self.scannedBeacons[(NSUInteger) indexPath.row];
    }
}


#pragma mark - Actions


- (IBAction)selectBeaconSource:(id)sender {
    UISegmentedControl *segmentedControl = sender;
    if (segmentedControl.selectedSegmentIndex == 0) {
        self.tableView.hidden = YES;
        self.uuidTextField.hidden = NO;
    }
    else {
        self.tableView.hidden = NO;
        self.uuidTextField.hidden = YES;
    }
}


- (IBAction)addAction:(id)sender {
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        BOOL isValid = [self isValidUUID:self.uuidTextField.text];
        if (!isValid) {
            NSError *error = [NSError errorWithDomain:kPBErrorDomain code:kPBUIErrorUUIDIsNotValidCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBUIErrorUUIDIsNotValid]}];
            [self showAlertError:error];
            return;
        }
        PBBeacon *beacon = [[PBBeacon alloc] init];
        beacon.beaconUid = self.uuidTextField.text;
        self.beacon = beacon;
    }
    if (self.beacon) {
        [self.delegate sender:self passData:self.beacon];
    }
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)cancelAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Application facade delegate methods


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveScannedBeacons:(NSArray *)beacons {
    [self updateBeacons:beacons];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailBluetoothServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:error];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:[PBError checkAndCreateInApplicationError:error]];
}


#pragma mark - Helper methods


- (BOOL)isValidUUID:(NSString *)UUIDString {
    NSUUID *UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
    return UUID != nil;
}


- (void)updateBeacons {
    if (![self.facade startScanning]) {
        return;
    }
    if (self.refreshControl && self.refreshControl.refreshing) {
        [self.scanningTimer fire];
        [self.refreshControl beginRefreshing];
    }
}


- (void)scanningDidEnd {
    [self.facade stopScanning];
    if (self.refreshControl && self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
}


- (void)updateBeacons:(NSArray *)beacons {
    self.scannedBeacons = beacons;
    [self.tableView reloadData];
}


- (void)selectItem:(id)sender {
    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    if (!((UIButton *) sender).selected) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
}


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
