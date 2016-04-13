//
//  PBHistoryViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 12/24/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import "PBHistoryViewController.h"
#import "PBHistoryTableViewCell.h"
#import "PBApplicationFacade.h"
#import "NSDate+TimeAgo.h"
#import "NSDate+RelativeDate.h"
#import "Constants.h"
#import "PBCardDetailViewController.h"
#import "PBError.h"


typedef NS_ENUM (NSInteger, PBHistorySelectedSorting) {
    PBHistorySelectedSortingNameAZ,
    PBHistorySelectedSortingNameZA,
    PBHistorySelectedSortingDate
};
static CGFloat const kSectionHeaderHeight = 35.0;


@interface PBHistoryViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, PBApplicationFacadeDelegate>


@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSDictionary *sections;
@property (nonatomic, strong) PBApplicationFacade *facade;
@property (nonatomic, strong) NSArray *sortedDays;
@property (nonatomic, strong) NSMutableArray *cards;
@property (nonatomic, assign) BOOL groupedView;
@property (nonatomic, assign) BOOL searchMode;
@property (nonatomic, assign) PBHistorySelectedSorting selectedSorting;

@end


@implementation PBHistoryViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    UIGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapper];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.refreshControl.tintColor = [UIColor darkGrayColor];
    [self.refreshControl addTarget:self action:@selector(loadCards) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    self.groupedView = YES;
    self.facade = [PBApplicationFacade sharedManager];
    self.selectedSorting = PBHistorySelectedSortingDate;
    // Do any additional setup after loading the view.
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


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groupedView ? [self.sections count] : 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *cardsOnThisDay = nil;
    if(self.sortedDays.count > 0){
        NSDate *dateRepresentingThisDay = self.sortedDays[(NSUInteger) section];
        cardsOnThisDay = self.sections[dateRepresentingThisDay];        
    }
    return self.groupedView ? [cardsOnThisDay count] : self.cards.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PBHistoryTableViewCell *cell = (PBHistoryTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"HistoryTableCellIdentifier"];

    NSArray *cardsOnThisDay = nil;
    if(self.sortedDays.count > 0){
        NSDate *dateRepresentingThisDay = self.sortedDays[(NSUInteger) indexPath.section];
        cardsOnThisDay = [self.sections[dateRepresentingThisDay] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self.visitDate" ascending:NO]]];
    }

    PBCard *card = nil;
    if (self.groupedView) {
        if (cardsOnThisDay && cardsOnThisDay.count > indexPath.row) {
            card = cardsOnThisDay[(NSUInteger) indexPath.row];
        }
    }
    else {
        if (self.cards && self.cards.count > indexPath.row) {
            card = self.cards[(NSUInteger) indexPath.row];
        }
    }
    if (card) {

        [self setFavorite:card.isFavourite forCell:cell];

        dispatch_async(dispatch_get_main_queue(), ^{
            cell.favoriteIcon.image = [UIImage imageNamed:@"cell_favorite_icon"];
            cell.cellImage.image = card.logo ? [UIImage imageWithData:card.logo] : [UIImage imageNamed:@"card_default_icon"];
            cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2;
            cell.cellImage.clipsToBounds = YES;
        });

        cell.cellTitle.text = card.title;
        cell.cellDetail.text = card.summary;
        cell.cellTime.text = [card.visitDate timeAgoSimple];

        __weak PBHistoryViewController *weakSelf = self;
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


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.groupedView ? kSectionHeaderHeight : CGFLOAT_MIN;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDate *dateRepresentingThisDay = nil;
    if(self.sortedDays.count > 0){
        dateRepresentingThisDay = self.sortedDays[(NSUInteger) section];
    }
    return self.groupedView ? [dateRepresentingThisDay relativeDateString] : nil;
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
    header.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0];
    header.textLabel.textColor = kTableSectionHeaderTextColor;
}


#pragma mark - Search bar delegate methods


- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchMode = YES;
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 0) {
        self.cards = [[self resultsForCardSearch:searchText] mutableCopy];
        self.groupedView = NO;
    }
    else {
        self.groupedView = YES;
    }
    [self.tableView reloadData];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchMode = NO;
    searchBar.text = @"";
    [searchBar endEditing:YES];
    self.groupedView = YES;
    [self.tableView reloadData];
}


#pragma mark - Application facade delegate methods


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:[PBError checkAndCreateInApplicationError:error]];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveDetailCardInfo:(PBCard *)card {
    [self updateCard:card];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedInfoCards:(NSArray *)cards {
    [self updateCards:cards];
}


#pragma mark - Helper methods


- (void)showAlertError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
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
    else{
        NSMutableDictionary *sections = [NSMutableDictionary dictionary];
        for (PBCard *card in cards) {
            NSDate *dateRepresentingThisDay = [self dateAtBeginningOfDayForDate:card.visitDate];

            // If we don't yet have an array to hold the events for this day, create one
            NSMutableArray *cardsOnThisDay = sections[dateRepresentingThisDay];
            if (cardsOnThisDay == nil) {
                cardsOnThisDay = [NSMutableArray array];

                // Use the reduced date as dictionary key to later retrieve the event list this day
                sections[dateRepresentingThisDay] = cardsOnThisDay;
            }

            [cardsOnThisDay addObject:card];
        }
        self.sections = sections;

        NSArray *unsortedDays = [self.sections allKeys];
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:NO];
        NSArray *descriptors = @[descriptor];
        self.sortedDays = [unsortedDays sortedArrayUsingDescriptors:descriptors];

        switch (self.selectedSorting) {

            case PBHistorySelectedSortingNameAZ: {
                [self sortByNameWithOrder:YES];
                break;
            }
            case PBHistorySelectedSortingNameZA: {
                [self sortByNameWithOrder:NO];
                break;
            }
            case PBHistorySelectedSortingDate: {
                [self sortByDate];
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
    NSDate *dateRepresentingThisDay = [self dateAtBeginningOfDayForDate:card.visitDate];
    if ([self.sortedDays containsObject:dateRepresentingThisDay]) {
        NSUInteger sectionNumber = [self.sortedDays indexOfObject:dateRepresentingThisDay];
        __block NSUInteger objectIndex;
        NSMutableArray *cardsForDay = self.sections[dateRepresentingThisDay];
        [cardsForDay enumerateObjectsUsingBlock:^(PBCard *cardInArray, NSUInteger index, BOOL *cancel) {
            if ([cardInArray isEqual:card]) {
                objectIndex = index;
                cardInArray.title = card.title;
                cardInArray.summary = card.summary;
                cardInArray.logo = card.logo;
                cardInArray.phones = card.phones;
                cardInArray.emails = card.emails;
                cardInArray.urls = card.urls;
                cardInArray.vCards = card.vCards;
                *cancel = YES;
            }
        }];

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:objectIndex inSection:sectionNumber];
        if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}


- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.searchBar endEditing:YES];
}


- (void)sortByNameWithOrder:(BOOL)order {
    self.selectedSorting = order ? PBHistorySelectedSortingNameAZ : PBHistorySelectedSortingNameZA;
    NSMutableArray *allCards = [NSMutableArray array];
    if (self.groupedView) {
        for (NSArray *array in [self.sections allValues]) {
            [allCards addObjectsFromArray:array];
        }
    }
    else {
        allCards = (NSMutableArray *) self.cards;
    }
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"self.title" ascending:order];
    NSArray *descriptors = @[descriptor];
    self.cards = [[allCards sortedArrayUsingDescriptors:descriptors] mutableCopy];
    self.groupedView = NO;
    [self.tableView reloadData];
}


- (void)sortByDate {
    self.selectedSorting = PBHistorySelectedSortingDate;
    self.groupedView = YES;
    [self.tableView reloadData];
}


- (NSArray *)resultsForCardSearch:(NSString *)searchText {
    NSMutableArray *allCards = [NSMutableArray array];
    for (NSArray *array in [self.sections allValues]) {
        [allCards addObjectsFromArray:array];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(title CONTAINS[c] %@) OR (summary CONTAINS[c] %@)", searchText, searchText];
    return [allCards filteredArrayUsingPredicate:predicate];
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


#pragma mark - Navigation


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CardDetailSegue"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *dateRepresentingThisDay = self.sortedDays[(NSUInteger) indexPath.section];
        NSArray *cardsOnThisDay = [self.sections[dateRepresentingThisDay] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self.visitDate" ascending:NO]]];


        PBCard *card = nil;
        if (self.groupedView) {
            if (cardsOnThisDay && cardsOnThisDay.count > indexPath.row) {
                card = cardsOnThisDay[(NSUInteger) indexPath.row];
            }
        }
        else {
            if (self.cards && self.cards.count > indexPath.row) {
                card = self.cards[(NSUInteger) indexPath.row];
            }
        }

        ((PBCardDetailViewController *) segue.destinationViewController).card = card;
    }
}


#pragma mark - Date Calculations


- (NSDate *)dateAtBeginningOfDayForDate:(NSDate *)inputDate {
    // Use the user's current calendar and time zone
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    [calendar setTimeZone:timeZone];

    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:inputDate];

    // Set the time components manually
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];

    // Convert back
    NSDate *beginningOfDay = [calendar dateFromComponents:dateComps];
    return beginningOfDay;
}


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
    UIAlertAction *sortDate = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sort by Date", @"Sort by Date") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sortByDate];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [actionSheet dismissViewControllerAnimated:YES completion:nil];
    }];
    [actionSheet addAction:sortNameAZ];
    [actionSheet addAction:sortNameZA];
    [actionSheet addAction:sortDate];
    [actionSheet addAction:cancel];

    [self presentViewController:actionSheet animated:YES completion:nil];
}

@end
