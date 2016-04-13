//
// Created by Oleksandr Malyarenko on 1/25/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol PBPassDataDelegate;
@protocol PBPassDataDelegate;


@interface PBLinkMyCardsViewController : UIViewController


@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *selectedCards;
@property (nonatomic, weak) id <PBPassDataDelegate> delegate;

- (IBAction)cancelAction:(id)sender;
- (IBAction)linkAction:(id)sender;
@end