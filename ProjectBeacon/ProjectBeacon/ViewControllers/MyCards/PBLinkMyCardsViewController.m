//
// Created by Oleksandr Malyarenko on 1/25/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import "PBMyCardTableViewCell.h"
#import "PBLinkMyCardsViewController.h"
#import "PBPassDataDelegate.h"
#import "PBApplicationFacadeDelegate.h"
#import "PBApplicationFacade.h"
#import "NSString+Enum.h"
#import "Constants.h"
#import "PBError.h"


@interface PBLinkMyCardsViewController () <UITableViewDataSource, UITableViewDelegate, PBApplicationFacadeDelegate>


@property (nonatomic, strong) NSMutableArray *cards;
@property (nonatomic, strong) PBApplicationFacade *facade;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSIndexPath *selectedRow;

@end


@implementation PBLinkMyCardsViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.selectedCards) {
        self.selectedCards = [NSMutableArray array];
    }

    self.facade = [PBApplicationFacade sharedManager];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.refreshControl.tintColor = [UIColor darkGrayColor];
    [self.refreshControl addTarget:self action:@selector(loadCards) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.facade.delegate = self;
    [self loadCards];
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
            if ([self.selectedCards containsObject:card]) {
                cell.selected = YES;
            }
            else{
                cell.selected = NO;
            }
        });

        cell.cardTitle.text = card.title;
        cell.cardDescription.text = card.summary;
        cell.cardPermission.text = [NSString stringFromCardPermission:card.permission];
        cell.linkedBeaconsCount.text = [NSString stringWithFormat:@"%ld", (long) card.beaconsCount];

        [cell.selectButton addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventTouchUpInside];

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
        card.isActive = YES;
        [self.selectedCards addObject:card];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.selected = YES;
    }
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    PBCard *card = nil;
    if (self.cards && self.cards.count > indexPath.row) {
        card = self.cards[(NSUInteger) indexPath.row];
    }
    if (card && [self.selectedCards containsObject:card]) {
        [self.selectedCards removeObject:card];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.selected = NO;
    }
}


#pragma mark - Application facade delegate methods


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedUserCards:(NSArray *)cards {
    [self updateCards:cards];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveDetailCardInfo:(PBCard *)card {
    [self updateCard:card];
}


- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error {
    DDLogError(@"%@: %@", NSStringFromClass([self class]), error.localizedDescription);
    [self showAlertError:[PBError checkAndCreateInApplicationError:error]];
}


#pragma mark - Actions


- (IBAction)cancelAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)linkAction:(id)sender {
    [self.delegate sender:self passData:self.selectedCards];
    [self.navigationController popViewControllerAnimated:YES];
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
    self.cards = [cards mutableCopy];
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
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
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