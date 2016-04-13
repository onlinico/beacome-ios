//
// Created by Oleksandr Malyarenko on 12/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>


@class PBApplicationFacade;
@class PBCard;
@class PBUser;


@protocol PBApplicationFacadeDelegate <NSObject>


@required

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailRetrievingInformationFromServiceWithError:(NSError *)error;

@optional

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didUpdateBluetoothStatus:(BOOL)status;

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveScannedBeacons:(NSArray *)beacons;

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveCardsForBeacon:(NSArray *)cards;

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedUserCards:(NSArray *)cards;

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedUserBeacons:(NSArray *)beacons;

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedInfoCards:(NSArray *)cards;

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveDetailCardInfo:(PBCard *)card;

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveDetailScanCardInfo:(PBCard *)card;

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didReceiveUpdatedUserInfo:(PBUser *)user;

- (void)applicationFacade:(PBApplicationFacade *)applicationFacade didFailBluetoothServiceWithError:(NSError *)error;

@end