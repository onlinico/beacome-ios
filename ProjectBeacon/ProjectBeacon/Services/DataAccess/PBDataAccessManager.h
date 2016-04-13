//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>
#import "Models.h"


static NSInteger const kPBDefaultUserId = -1;
static NSString *const kDefaultShareGuid = @"00000000-0000-0000-0000-000000000000";

@class PBBeacon;


@interface PBDataAccessManager : NSObject


#pragma mark - Data access methods

- (void)cleanAnonymusData;

- (void)getDefaultUserWithCallback:(void (^)(PBUser *user))callback;

- (void)getUserById:(NSInteger)id callback:(void (^)(PBUser *user))callback;

- (void)addUser:(PBUser *)user;

- (void)updateUser:(PBUser *)user;

- (void)copyAnonymusUserHistoryToUser:(NSInteger)userId;

- (void)getAllUserCards:(NSInteger)userId callback:(void (^)(NSArray *cards))callback;

- (void)getAllInfoCards:(NSInteger)userId callback:(void (^)(NSArray *cards))callback;

- (void)getCardByUid:(NSString *)cardId callback:(void (^)(PBCard *card))callback;

- (void)getDetailsForCard:(PBCard *)card isUserCard:(BOOL)isUserCard callback:(void (^)(PBCard *detailCard))callback;

- (void)addShares:(NSArray *)shares toCardId:(NSString *)cardId;

- (void)updateShares:(NSArray *)shares forCardId:(NSString *)cardId;

- (void)deleteShares:(NSArray *)shares forCardId:(NSString *)cardId;

- (void)getInfoCards:(NSInteger)userId fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate callback:(void (^)(NSArray *cards))callback;

- (void)cardExist:(PBCard *)card callback:(void (^)(BOOL exist, PBCard *existedCard))callback;

- (void)addCard:(PBCard *)card;

- (void)addCard:(PBCard *)card forUser:(NSInteger)userId;

- (void)updateCard:(PBCard *)card;

- (void)updateCard:(PBCard *)card forUser:(NSInteger)userId;
- (void)deleteCard:(PBCard *)card fromUser:(NSInteger)userId;

- (void)cardHistoryExist:(NSString *)cardId forUser:(NSInteger)userId callback:(void (^)(BOOL exist, PBCardHistory *cardHistory))callback;

- (void)addCardHistory:(PBCardHistory *)cardHistory toUser:(NSInteger)userId;

- (void)updateCardHistory:(PBCardHistory *)cardHistory forUser:(NSInteger)userId;

- (void)deleteCardHistory:(PBCardHistory *)cardHistory forUser:(NSInteger)userId;

- (void)beaconExist:(PBBeacon *)beacon callback:(void (^)(BOOL exist))callback;

- (void)getAllBeaconsForUser:(NSInteger)userId withCallback:(void (^)(NSArray *beacons))callback;

- (void)getBeaconsForCard:(PBCard *)card callback:(void (^)(NSArray *beacons))callback;

- (void)getCardsForBeacon:(PBBeacon *)beacon callback:(void (^)(NSArray *cards))callback;

- (void)getBeaconByUid:(NSString *)beaconUid callback:(void (^)(PBBeacon *beacon))callback;

- (void)addBeacon:(PBBeacon *)beacon;

- (void)addBeacon:(PBBeacon *)beacon toCard:(PBCard *)card;

- (void)updateBeacon:(PBBeacon *)beacon;

- (void)deleteBeacon:(PBBeacon *)beacon;

- (void)linkBeacon:(PBBeacon *)beacon toCard:(PBCard *)card;

- (void)unlinkBeacon:(PBBeacon *)beacon fromCard:(PBCard *)card;

- (void)vCardExist:(PBVCard *)vCard callback:(void (^)(BOOL exist, PBVCard *existedVCard))callback;

- (void)getVCardsForCardGuid:(NSString *)cardId callback:(void (^)(NSArray *vCards))callback;

/*- (void)addVCard:(PBVCard *)vCard;

- (void)updateVCard:(PBVCard *)vCard;

- (void)deleteVCard:(PBVCard *)vCard;*/

@end