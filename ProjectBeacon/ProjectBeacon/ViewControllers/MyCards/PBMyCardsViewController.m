//
//  PBMyCardsViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/28/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import "PBMyCardTableViewCell.h"
#import "PBMyCardsViewController.h"
#import "PBApplicationFacadeDelegate.h"
#import "PBApplicationFacade.h"
#import "NSString+Enum.h"
#import "Constants.h"
#import "PBLinkBeaconViewController.h"
#import "PBNewCardViewController.h"
#import "PBPassDataDelegate.h"
#import "PBShareCardViewController.h"
#import "PBError.h"
#import "PBMyCardDetailViewController.h"


typedef NS_ENUM (NSInteger, PBMyCardsSelectedSorting) {
    PBMyCardsSelectedSortingNameAZ,
    PBMyCardsSelectedSortingNameZA,
    PBMyCardsSelectedSortingRole,
    PBMyCardsSelectedSortingMyBeacons
};


@interface PBMyCardsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, PBApplicationFacadeDelegate, PBPassDataDelegate>


@property (nonatomic, strong) NSMutableArray *cards;
@property (nonatomic, strong) NSArray *originalSource;
@property (nonatomic, strong) PBApplicationFacade *facade;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSIndexPath *selectedRow;
@property (nonatomic, assign) BOOL searchMode;
@property (nonatomic, assign) PBMyCardsSelectedSorting selectedSorting;

@end


@implementation PBMyCardsViewController


- (void)viewDidLoad {
    [super viewDidLoad];
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
    [self.refreshControl addTarget:self action:@selector(loadCards) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    self.facade = [PBApplicationFacade sharedManager];
    self.facade.delegate = self;
    if (!self.searchMode) {
        [self loadCards];
    }
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


#pragma mark - Table view data source methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cards.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PBMyCardTableViewCell *cell = (PBMyCardTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"UserCardCellIdentifier"];

    PBCard *card = nil;
    if (self.cards && self.cards.count > indexPath.row) {
        card = self.cards[(NSUInteger) indexPath.row];
    }
    if (card) {
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.cardImage.image = card.logo ? [UIImage imageWithData:card.logo] : [UIImage imageNamed:@"card_default_icon"];
            cell.cardImage.layer.cornerRadius = cell.cardImage.frame.size.width / 2;
            cell.cardImage.clipsToBounds = YES;
        });

        cell.cardTitle.text = card.title;
        cell.cardDescription.text = card.summary;
        cell.cardPermission.text = [NSString stringFromCardPermission:card.permission];
        cell.linkedBeaconsCount.text = [NSString stringWithFormat:@"%ld", (long) card.beaconsCount];

        if (!self.selectionMode) {
            __weak PBMyCardsViewController *weakSelf = self;
            cell.selectButton.hidden = YES;
            MGSwipeButton *linkButton = [MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"link_button"] backgroundColor:kSwipeCellButtonColor callback:^BOOL(MGSwipeTableCell *sender) {
                weakSelf.selectedRow = indexPath;
                PBLinkBeaconViewController *linkBeaconViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"PBLinkBeaconViewController"];
                PBCard *object = weakSelf.cards[(NSUInteger) weakSelf.selectedRow.row];
                linkBeaconViewController.selectedBeacons = [object.beacons mutableCopy];
                linkBeaconViewController.delegate = weakSelf;
                [weakSelf.navigationController pushViewController:linkBeaconViewController animated:YES];

                return YES;
            }];
            MGSwipeButton *unlinkButton = [MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"unlink_button"] backgroundColor:kSwipeCellButtonColor callback:^BOOL(MGSwipeTableCell *sender) {
                weakSelf.selectedRow = indexPath;
                PBLinkBeaconViewController *linkBeaconViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"PBLinkBeaconViewController"];
                PBCard *object = weakSelf.cards[(NSUInteger) weakSelf.selectedRow.row];
                linkBeaconViewController.selectedBeacons = [object.beacons mutableCopy];
                linkBeaconViewController.delegate = weakSelf;
                [weakSelf.navigationController pushViewController:linkBeaconViewController animated:YES];
                return YES;
            }];
            MGSwipeButton *shareButton = [MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"share_button"] backgroundColor:kSwipeCellButtonColor callback:^BOOL(MGSwipeTableCell *sender) {
                weakSelf.selectedRow = indexPath;
                PBShareCardViewController *shareCardViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"PBShareCardViewController"];
                shareCardViewController.delegate = weakSelf;
                weakSelf.navigationController.definesPresentationContext = YES;
                shareCardViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                shareCardViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                [weakSelf.tabBarController presentViewController:shareCardViewController animated:YES completion:nil];
                return YES;
            }];
            MGSwipeButton *deleteButton = [MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"delete_button"] backgroundColor:kSwipeCellButtonColor callback:^BOOL(MGSwipeTableCell *sender) {
                [weakSelf.facade deleteCard:card callback:^(BOOL result) {
                    if (result) {
                        [weakSelf.cards removeObjectAtIndex:(NSUInteger) indexPath.row];
                        [weakSelf.tableView reloadData];
                    }
                }];
                return YES;
            }];
            cell.rightButtons = card.permission ? @[deleteButton, shareButton, linkButton, unlinkButton] : @[linkButton, unlinkButton];
        }
        else {
            cell.selectButton.hidden = NO;
            if ([self.selectedCards containsObject:card]) {
                cell.selected = YES;
            }
            [cell.selectButton addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventTouchUpInside];
        }

    }
    [cell setNeedsLayout];

    return cell;
}


#pragma mark - Table view delegate methods


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PBCard *card = nil;
    if (self.cards && self.cards.count > indexPath.row) {
        card = self.cards[(NSUInteger) indexPath.row];
    }
    if (card) {
        [self.selectedCards addObject:card];
    }
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    PBCard *card = nil;
    if (self.cards && self.cards.count > indexPath.row) {
        card = self.cards[(NSUInteger) indexPath.row];
    }
    if (card && [self.selectedCards containsObject:card]) {
        [self.selectedCards removeObject:card];
    }
}


#pragma mark - Search bar delegate methods


- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (!self.searchMode) {
        self.originalSource = [self.cards mutableCopy];
    }
    self.searchMode = YES;
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchMode = NO;
    searchBar.text = @"";
    [searchBar endEditing:YES];
    self.cards = [self.originalSource mutableCopy];
    [self.tableView reloadData];
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 0) {
        self.cards = [[self resultsForCardSearch:searchText] mutableCopy];
    }
    else {
        self.cards = [self.originalSource mutableCopy];
    }
    [self.tableView reloadData];
}


#pragma mark - Application facade delegate methods


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedUserCards:(NSArray *)cards {
    if (cards.count > 0) {
        [self updateCards:cards];
    }
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveDetailCardInfo:(PBCard *)card {
    [self updateCard:card];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:[PBError checkAndCreateInApplicationError:error]];
}


#pragma mark - Table view delegate methods


#pragma mark - Navigation


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"NewCardSegue"]) {
        self.tabBarController.tabBar.hidden = YES;
        ((PBNewCardViewController *) segue.destinationViewController).actionsToolbar.hidden = NO;
        ((PBNewCardViewController *) segue.destinationViewController).delegate = self;
    }
    if ([segue.identifier isEqualToString:@"MyCardDetailSegue"]) {
        self.tabBarController.tabBar.hidden = YES;
        ((PBMyCardDetailViewController *) segue.destinationViewController).card = self.cards[(NSUInteger) [[self.tableView indexPathForSelectedRow] row]];
    }
}


#pragma mark -Pass data delegate


- (void)sender:(id)sender passData:(id)data {
    __weak PBMyCardsViewController *weakSelf = self;
    if ([sender isMemberOfClass:[PBLinkBeaconViewController class]]) {
        NSArray *linkedBeacons = data;
        if (self.selectedRow) {
            __block PBCard *card = self.cards[(NSUInteger) self.selectedRow.row];
            PBCard *newCard = [card copy];
            newCard.beacons = linkedBeacons;
            [self.facade updateBeaconsInCard:newCard oldCard:card callback:^(PBCard *updated) {
                [self updateCard:updated];
            }];
        }
    }
    if ([sender isMemberOfClass:[PBNewCardViewController class]]) {
        PBCard *card = data;
        [self.facade addNewCard:card callback:^(BOOL result, PBCard *addedCard) {
            [weakSelf updateCard:addedCard];
        }];
    }
    if ([sender isMemberOfClass:[PBShareCardViewController class]]) {
        PBCardsShare *cardShare = data;
        [self.facade shareCard:self.cards[(NSUInteger) self.selectedRow.row] toPerson:cardShare andSave:YES callback:^(BOOL result, PBCardsShare *share) {
            if (!result) {
                NSError *error = [NSError errorWithDomain:kPBErrorDomain code:kPBServiceErrorCantShareCardCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBServiceErrorCantShareCard]}];
                [weakSelf showAlertError:error];
            }
        }];
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
    UIAlertAction *sortRole = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sort by My Role", @"Sort by My Role") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sortByRole];
    }];
    UIAlertAction *sortBeaconsCount = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sort by My Beacons", @"Sort by My Beacons") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sortByBeaconsCount];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [actionSheet dismissViewControllerAnimated:YES completion:nil];
    }];
    [actionSheet addAction:sortNameAZ];
    [actionSheet addAction:sortNameZA];
    [actionSheet addAction:sortRole];
    [actionSheet addAction:sortBeaconsCount];
    [actionSheet addAction:cancel];

    [self presentViewController:actionSheet animated:YES completion:nil];
}


#pragma mark - Helper methods


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)loadCards {
    [self.facade getUserCardsWithCallback:^(NSArray *results) {
        [self updateCards:results];
    }];
}


- (void)updateCards:(NSArray *)cards {
    if (self.searchMode) {
        [cards enumerateObjectsUsingBlock:^(PBCard *card, NSUInteger index, BOOL *stop) {
            if ([self.cards containsObject:card]) {
                self.cards[[self.cards indexOfObject:card]] = card;
            }
        }];
    }
    else {
        self.cards = [cards mutableCopy];
        switch (self.selectedSorting) {

            case PBMyCardsSelectedSortingNameAZ: {
                [self sortByNameWithOrder:YES];
                break;
            }
            case PBMyCardsSelectedSortingNameZA: {
                [self sortByNameWithOrder:NO];
                break;
            }
            case PBMyCardsSelectedSortingRole: {
                [self sortByRole];
                break;
            }
            case PBMyCardsSelectedSortingMyBeacons: {
                [self sortByBeaconsCount];
                break;
            }
        }
    }

    [self.tableView reloadData];
    if (self.refreshControl && self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
}


- (void)updateCard:(PBCard *)card {
    if ([self.cards containsObject:card]) {
        self.cards[[self.cards indexOfObject:card]] = card;
        [self.tableView reloadData];
    }
}


- (NSArray *)resultsForCardSearch:(NSString *)searchText {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(title CONTAINS[c] %@) OR (summary CONTAINS[c] %@)", searchText, searchText];
    return [self.originalSource filteredArrayUsingPredicate:predicate];
}


- (void)sortByNameWithOrder:(BOOL)order {
    self.selectedSorting = order ? PBMyCardsSelectedSortingNameAZ : PBMyCardsSelectedSortingNameZA;
    NSArray *allCards = self.cards;
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"self.title" ascending:order];
    NSArray *descriptors = @[descriptor];
    self.cards = [[allCards sortedArrayUsingDescriptors:descriptors] mutableCopy];
    [self.tableView reloadData];
}


- (void)sortByRole {
    self.selectedSorting = PBMyCardsSelectedSortingRole;
    NSArray *allCards = self.cards;
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"self.permission" ascending:YES];
    NSArray *descriptors = @[descriptor];
    self.cards = [[allCards sortedArrayUsingDescriptors:descriptors] mutableCopy];
    [self.tableView reloadData];
}


- (void)sortByBeaconsCount {
    self.selectedSorting = PBMyCardsSelectedSortingMyBeacons;
    NSArray *allCards = self.cards;
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"self.beaconsCount" ascending:YES];
    NSArray *descriptors = @[descriptor];
    self.cards = [[allCards sortedArrayUsingDescriptors:descriptors] mutableCopy];
    [self.tableView reloadData];
}


- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.searchBar endEditing:YES];
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

@end
