//
//  PBScanningViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/23/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//


#import "PBScanningViewController.h"
#import "PBCard.h"
#import "PBHistoryTableViewCell.h"
#import "PBApplicationFacade.h"
#import "NSDate+TimeAgo.h"
#import "Constants.h"
#import "PBCardDetailViewController.h"
#import "PBError.h"

typedef NS_ENUM (NSInteger, PBScanningSelectedSorting){
    PBScanningSelectedSortingNameAZ,
    PBScanningSelectedSortingNameZA
};

@interface PBScanningViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, PBApplicationFacadeDelegate>


@property (nonatomic, strong) NSMutableArray *cards;
@property (nonatomic, strong) NSArray *originalSource;
@property (nonatomic, strong) PBApplicationFacade *facade;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) BOOL searchMode;
@property (nonatomic, assign) PBScanningSelectedSorting selectedSorting;

@end


@implementation PBScanningViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.facade = [PBApplicationFacade sharedManager];
    self.cards = [NSMutableArray array];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    UIGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapper];

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.refreshControl.tintColor = [UIColor darkGrayColor];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.watchingSwitch.on = self.facade.isWatching;
    if (!self.searchMode) {
        self.cards = [[[self.facade getCardsWatchedInRange] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self.title" ascending:YES]]] mutableCopy];
    }
    switch (self.selectedSorting){

        case PBScanningSelectedSortingNameAZ:{
            [self sortByNameWithOrder:YES];
            break;
        }
        case PBScanningSelectedSortingNameZA:{
            [self sortByNameWithOrder:NO];
            break;
        }
    }
    [self.tableView reloadData];
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
    PBHistoryTableViewCell *cell = (PBHistoryTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"ScanningTableCellIdentifier"];

    PBCard *card = nil;
    if (self.cards && self.cards.count > indexPath.row) {
        card = self.cards[(NSUInteger) indexPath.row];
    }
    if (card) {
        [self setFavorite:card.isFavourite forCell:cell];

        dispatch_async(dispatch_get_main_queue(), ^{
            cell.favoriteIcon.image = [UIImage imageNamed:@"cell_favorite_icon"];
            cell.cellImage.image = card.logo ? [UIImage imageWithData:card.logo] : [UIImage imageNamed:@"card_default_icon"];
            cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2;
            cell.cellImage.clipsToBounds = YES;
        });

        NSLayoutConstraint *timeLabelWidthConstraint = [self getConstraintByName:@"timeTitleZeroWidthConstraint" inCell:cell];
        timeLabelWidthConstraint.priority = 900;

        cell.cellTitle.text = card.title;
        cell.cellDetail.text = card.summary;
        cell.cellTime.text = [card.visitDate timeAgoSimple];

        __weak PBScanningViewController *weakSelf = self;
        MGSwipeButton *favoriteButton = [MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"favorite_button"] backgroundColor:kSwipeCellButtonColor callback:^BOOL(MGSwipeTableCell *sender) {
            card.isFavourite = !card.isFavourite;
            [weakSelf.facade setCard:card favorite:card.isFavourite callback:^(BOOL result) {
                if (result) {
                    [weakSelf setFavorite:card.isFavourite forCell:cell];
                }
            }];
            return YES;
        }];
        cell.rightButtons = @[favoriteButton];
        cell.rightSwipeSettings.transition = MGSwipeTransitionDrag;

    }
    [cell setNeedsLayout];

    return cell;
}


#pragma mark - Table view delegate methods

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [self performSegueWithIdentifier:@"ShowScanningCardDetail" sender:self];
//}

#pragma mark - Search bar delegate methods


- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if(!self.searchMode){
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


#pragma mark - Navigation


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CardDetailSegue"]) {
        ((PBCardDetailViewController *) segue.destinationViewController).card = self.cards[(NSUInteger) [[self.tableView indexPathForSelectedRow] row]];
    }
}


#pragma mark - Application facade delegate methods


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didUpdateBluetoothStatus:(BOOL)status {
    self.watchingSwitch.on = status;
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveCardsForBeacon:(NSArray *)cards {
    cards = [cards sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self.title" ascending:YES]]];
    [self.facade compareLocalCards:self.cards withWebCards:cards result:^(NSArray *arrayForAdd, NSArray *arrayForDelete, NSArray *arrayForUpdate) {
        [arrayForAdd enumerateObjectsUsingBlock:^(PBCard *card, NSUInteger index, BOOL *stop) {
            [self.cards addObject:card];
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(self.cards.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }];
        [arrayForUpdate enumerateObjectsUsingBlock:^(PBCard *card, NSUInteger index, BOOL *stop) {
            NSUInteger row = [self.cards indexOfObject:card];
            self.cards[row] = card;
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }];
        [arrayForDelete enumerateObjectsUsingBlock:^(PBCard *card, NSUInteger index, BOOL *stop) {
            NSUInteger row = [self.cards indexOfObject:card];
            [self.cards removeObjectAtIndex:row];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }];
    }];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveDetailScanCardInfo:(PBCard *)card {
    [self updateCard:card];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:[PBError checkAndCreateInApplicationError:error]];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailBluetoothServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    self.watchingSwitch.on = NO;
    [self showAlertError:error];
}


#pragma mark - Helper methods


- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.searchBar endEditing:YES];
}


- (void)updateCard:(PBCard *)card {
    if ([self.cards containsObject:card]) {
        NSUInteger index = [self.cards indexOfObject:card];
        self.cards[index] = card;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}


- (void)setFavorite:(BOOL)favorite forCell:(PBHistoryTableViewCell *)cell {
    if (favorite) {
        NSLayoutConstraint *heightFavoriteIcon = [self getConstraintByName:@"heightFavoriteIcon" inCell:cell];
        NSLayoutConstraint *widthFavoriteIcon = [self getConstraintByName:@"widthFavoriteIcon" inCell:cell];
        NSLayoutConstraint *leadingWithFavoriteIcon = [self getConstraintByName:@"leadingWithFavoriteIcon" inCell:cell];

        heightFavoriteIcon.priority = 900;
        widthFavoriteIcon.priority = 900;
        leadingWithFavoriteIcon.priority = 900;
    }
    else {
        NSLayoutConstraint *heightFavoriteIcon = [self getConstraintByName:@"heightFavoriteIcon" inCell:cell];
        NSLayoutConstraint *widthFavoriteIcon = [self getConstraintByName:@"widthFavoriteIcon" inCell:cell];
        NSLayoutConstraint *leadingWithFavoriteIcon = [self getConstraintByName:@"leadingWithFavoriteIcon" inCell:cell];

        heightFavoriteIcon.priority = 250;
        widthFavoriteIcon.priority = 250;
        leadingWithFavoriteIcon.priority = 250;
    }
}


- (NSLayoutConstraint *)getConstraintByName:(NSString *)name inCell:(PBHistoryTableViewCell *)cell {
    NSLayoutConstraint *result = nil;
    for (NSLayoutConstraint *constraint in cell.cellConstraints) {
        if ([constraint.identifier isEqualToString:name]) {
            result = constraint;
            break;
        }
    }

    return result;
}


- (NSArray *)resultsForCardSearch:(NSString *)searchText {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(title CONTAINS[c] %@) OR (summary CONTAINS[c] %@)", searchText, searchText];
    return [self.originalSource filteredArrayUsingPredicate:predicate];
}


- (void)sortByNameWithOrder:(BOOL)order {
    self.selectedSorting = order ? PBScanningSelectedSortingNameAZ : PBScanningSelectedSortingNameZA;
    NSArray *allCards = self.cards;
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"self.title" ascending:order];
    NSArray *descriptors = @[descriptor];
    self.cards = [[allCards sortedArrayUsingDescriptors:descriptors] mutableCopy];
    [self.tableView reloadData];
}


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (IBAction)switchWatchingMode:(id)sender {
    UISwitch *switcher = sender;
    if (switcher.isOn) {
        switcher.on = [self.facade startWatching];
    }
    else {
        switcher.on = [self.facade stopWatching];
        [self.cards removeAllObjects];
        [self.tableView reloadData];
    }
}


- (IBAction)showSortView:(id)sender {
    if(self.searchMode){
        [self searchBarCancelButtonClicked:self.searchBar];
    }
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *sortNameAZ = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sort by Name: A to Z", @"Sort by Name: A to Z") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sortByNameWithOrder:YES];
    }];
    UIAlertAction *sortNameZA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sort by Name: Z to A", @"Sort by Name: Z to A") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sortByNameWithOrder:NO];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [actionSheet dismissViewControllerAnimated:YES completion:nil];
    }];
    [actionSheet addAction:sortNameAZ];
    [actionSheet addAction:sortNameZA];
    [actionSheet addAction:cancel];

    [self presentViewController:actionSheet animated:YES completion:nil];
}

@end
