//
//  PBFavoritesViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/24/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import "PBFavoritesViewController.h"
#import "PBCard.h"
#import "PBHistoryTableViewCell.h"
#import "PBApplicationFacade.h"
#import "NSDate+TimeAgo.h"
#import "Constants.h"
#import "PBCardDetailViewController.h"


typedef NS_ENUM (NSInteger, PBFavoritesSelectedSorting) {
    PBFavoritesSelectedSortingNameAZ,
    PBFavoritesSelectedSortingNameZA
};


@interface PBFavoritesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, PBApplicationFacadeDelegate>


@property (nonatomic, strong) NSMutableArray *cards;
@property (nonatomic, strong) NSArray *originalSource;
@property (nonatomic, strong) PBApplicationFacade *facade;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSIndexPath *selectedRow;
@property (nonatomic, assign) BOOL searchMode;
@property (nonatomic, assign) PBFavoritesSelectedSorting selectedSorting;

@end


@implementation PBFavoritesViewController


- (void)viewDidLoad {
    [super viewDidLoad];

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
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.facade.delegate = self;

    if (!self.searchMode) {
        [self loadCards];
    }
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
    __weak PBFavoritesViewController *weakSelf = self;
    PBHistoryTableViewCell *cell = (PBHistoryTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"FavoritesTableCellIdentifier"];

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

        MGSwipeButton *favoriteButton = [MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"favorite_button"] backgroundColor:kSwipeCellButtonColor callback:^BOOL(MGSwipeTableCell *sender) {
            weakSelf.selectedRow = indexPath;
            card.isFavourite = !card.isFavourite;
            [self.facade setCard:card favorite:card.isFavourite callback:^(BOOL result) {
                if (result && weakSelf.cards.count > weakSelf.selectedRow.row) {
                    [weakSelf.cards removeObjectAtIndex:(NSUInteger) weakSelf.selectedRow.row];
                    [weakSelf.tableView reloadData];
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


#pragma mark - Navigation


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CardDetailSegue"]) {
        ((PBCardDetailViewController *) segue.destinationViewController).card = self.cards[(NSUInteger) [[self.tableView indexPathForSelectedRow] row]];
    }
}


#pragma mark - Application facade delegate methods


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedInfoCards:(NSArray *)cards {
    [self updateCards:cards];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);


    [self showAlertError:error];
}


#pragma mark - Helper methods


- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.searchBar endEditing:YES];
}


- (void)loadCards {
    [self.facade loadCardsHistoryWithCallback:^(NSArray *results) {
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
        self.cards = [[cards filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"isFavourite = %d", YES]]] mutableCopy];
        switch (self.selectedSorting) {

            case PBFavoritesSelectedSortingNameAZ: {
                [self sortByNameWithOrder:YES];
                break;
            }
            case PBFavoritesSelectedSortingNameZA: {
                [self sortByNameWithOrder:NO];
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


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (NSArray *)resultsForCardSearch:(NSString *)searchText {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(title CONTAINS[c] %@) OR (summary CONTAINS[c] %@)", searchText, searchText];
    return [self.originalSource filteredArrayUsingPredicate:predicate];
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


- (void)sortByNameWithOrder:(BOOL)order {
    self.selectedSorting = order ? PBFavoritesSelectedSortingNameAZ : PBFavoritesSelectedSortingNameZA;
    NSArray *allCards = self.cards;
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"self.title" ascending:order];
    NSArray *descriptors = @[descriptor];
    self.cards = [[allCards sortedArrayUsingDescriptors:descriptors] mutableCopy];
    [self.tableView reloadData];
}


#pragma mark - View controller actions


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
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [actionSheet dismissViewControllerAnimated:YES completion:nil];
    }];
    [actionSheet addAction:sortNameAZ];
    [actionSheet addAction:sortNameZA];
    [actionSheet addAction:cancel];

    [self presentViewController:actionSheet animated:YES completion:nil];
}

@end
