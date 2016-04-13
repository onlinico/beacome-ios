//
//  PBMyBeaconsViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/5/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBMyBeaconsViewController.h"
#import "PBApplicationFacade.h"
#import "PBBeaconTableViewCell.h"
#import "PBBeaconDetailViewController.h"
#import "Constants.h"
#import "PBError.h"


typedef NS_ENUM(NSInteger, PBMyBeaconsSelectedSorting) {
    PBMyBeaconsSelectedSortingNameAZ,
    PBMyBeaconsSelectedSortingNameZA,
    PBMyBeaconsSelectedSortingLinkedCardsASC,
    PBMyBeaconsSelectedSortingLinkedCardsDESC
};


@interface PBMyBeaconsViewController () <UITableViewDelegate, UISearchBarDelegate, PBApplicationFacadeDelegate, UITableViewDataSource>


@property (nonatomic, strong) NSMutableArray *beacons;
@property (nonatomic, strong) NSArray *originalSource;
@property (nonatomic, strong) PBApplicationFacade *facade;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) BOOL searchMode;
@property (nonatomic, assign) PBMyBeaconsSelectedSorting selectedSorting;

@end


@implementation PBMyBeaconsViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setHidesBackButton:YES];
    // Do any additional setup after loading the view.
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    UIGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapper];
    // Do any additional setup after loading the view.

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.refreshControl.tintColor = [UIColor darkGrayColor];
    [self.refreshControl addTarget:self action:@selector(loadBeacons) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    self.facade = [PBApplicationFacade sharedManager];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.facade.delegate = self;
    if (!self.searchMode) {
        [self loadBeacons];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view datasource methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.beacons.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PBBeaconTableViewCell *cell = (PBBeaconTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"BeaconsTableCellIdentifier"];

    PBBeacon *beacon = nil;
    if (self.beacons && self.beacons.count > indexPath.row) {
        beacon = self.beacons[(NSUInteger) indexPath.row];
    }
    if (beacon) {
        cell.beaconUid.text = beacon.beaconUid;
        cell.linkedCardsCount.text = [NSString stringWithFormat:@"%ld", (long) beacon.linkedCardsCount];
    }

    return cell;
}


#pragma mark - Search bar delegate methods


- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (!self.searchMode) {
        self.originalSource = [self.beacons mutableCopy];
    }
    self.searchMode = YES;
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchMode = NO;
    searchBar.text = @"";
    [searchBar endEditing:YES];
    self.beacons = [self.originalSource mutableCopy];
    [self.tableView reloadData];
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 0) {
        self.beacons = [[self resultsForCardSearch:searchText] mutableCopy];
    }
    else {
        self.beacons = [self.originalSource mutableCopy];
    }
    [self.tableView reloadData];
}


#pragma mark - Application facade delegate


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:[PBError checkAndCreateInApplicationError:error]];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedUserBeacons:(NSArray *)beacons {
    [self updateBeacons:beacons];
}


#pragma mark - Navigation


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"BeaconDetailSegue"]) {
        PBBeaconDetailViewController *detailViewController = segue.destinationViewController;
        detailViewController.deviceAsBeacon = NO;
        detailViewController.beacon = self.beacons[(NSUInteger) [[self.tableView indexPathForSelectedRow] row]];
    }
}


#pragma mark - Actions


- (IBAction)showSortView:(id)sender {
    if (self.searchMode) {
        [self searchBarCancelButtonClicked:self.searchBar];
    }
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *sortNameAZ = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sort by Name: A to Z", @"Sort by Name: A to Z") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sortByNameWithOrder:YES];
    }];
    UIAlertAction *sortNameZA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sort by Name: Z to A", @"Sort by Name: Z to A") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sortByNameWithOrder:NO];
    }];
    UIAlertAction *sortCountAsc = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sort by linked cards: ASC", @"Sort by linked cards: ASC") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sortByLinkedCardsWithOrder:YES];
    }];
    UIAlertAction *sortCountDesc = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sort by linked cards: DESC", @"Sort by linked cards: DESC") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sortByLinkedCardsWithOrder:NO];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [actionSheet dismissViewControllerAnimated:YES completion:nil];
    }];
    [actionSheet addAction:sortNameAZ];
    [actionSheet addAction:sortNameZA];
    [actionSheet addAction:sortCountAsc];
    [actionSheet addAction:sortCountDesc];
    [actionSheet addAction:cancel];

    [self presentViewController:actionSheet animated:YES completion:nil];
}


#pragma mark - Helper methods


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)sortByNameWithOrder:(BOOL)order {
    self.selectedSorting = order ? PBMyBeaconsSelectedSortingNameAZ : PBMyBeaconsSelectedSortingNameZA;
    NSArray *allBeacons = self.beacons;
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"self.beaconUid" ascending:order];
    NSArray *descriptors = @[descriptor];
    self.beacons = [[allBeacons sortedArrayUsingDescriptors:descriptors] mutableCopy];
    [self.tableView reloadData];
}


- (void)sortByLinkedCardsWithOrder:(BOOL)order {
    self.selectedSorting = order ? PBMyBeaconsSelectedSortingLinkedCardsASC : PBMyBeaconsSelectedSortingLinkedCardsDESC;
    NSArray *allBeacons = self.beacons;
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"self.linkedCardsCount" ascending:order];
    NSArray *descriptors = @[descriptor];
    self.beacons = [[allBeacons sortedArrayUsingDescriptors:descriptors] mutableCopy];
    [self.tableView reloadData];
}


- (NSArray *)resultsForCardSearch:(NSString *)searchText {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(beaconUid CONTAINS[c] %@)", searchText];
    return [self.originalSource filteredArrayUsingPredicate:predicate];
}


- (void)loadBeacons {
    [self.facade loadUserBeaconsWithCallback:^(NSArray *results) {
        [self updateBeacons:results];
    }];
}


- (void)updateBeacons:(NSArray *)beacons {
    if (self.searchMode) {
        [beacons enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
            if ([self.beacons containsObject:beacon]) {
                self.beacons[[self.beacons indexOfObject:beacon]] = beacon;
            }
        }];
    }
    else {
        self.beacons = [beacons mutableCopy];
        switch (self.selectedSorting) {

            case PBMyBeaconsSelectedSortingNameAZ: {
                [self sortByNameWithOrder:YES];
                break;
            }
            case PBMyBeaconsSelectedSortingNameZA: {
                [self sortByNameWithOrder:NO];
                break;
            }
            case PBMyBeaconsSelectedSortingLinkedCardsASC: {
                [self sortByLinkedCardsWithOrder:YES];
                break;
            }
            case PBMyBeaconsSelectedSortingLinkedCardsDESC: {
                [self sortByLinkedCardsWithOrder:NO];
                break;
            }
        }
    }

    [self.tableView reloadData];
    if (self.refreshControl && self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
}


- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.searchBar endEditing:YES];
}

@end
