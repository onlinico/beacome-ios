//
// Created by Oleksandr Malyarenko on 12/7/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Models.h"
#import "PBApplicationFacadeDelegate.h"


@class PBCardsShare;

static NSString *const kFacebookAuthProvider = @"Facebook";
static NSString *const kTwitterAuthProvider = @"Twitter";
static NSString *const kGoogleAuthProvider = @"Google";


@interface PBApplicationFacade : NSObject


@property (nonatomic, assign) id <PBApplicationFacadeDelegate> delegate;

@property (nonatomic, assign) NSInteger userId;


+ (id)sharedManager;

- (BOOL)isAnonymus;

- (BOOL)isFirstLaunch;

- (BOOL)needsLogin;

- (PBBeacon *)getDeviceAsBeaconInfo;

- (BOOL)isWatching;

- (BOOL)isPublishing;

- (BOOL)startPublishing;

- (BOOL)startWatching;

- (BOOL)startScanning;

- (BOOL)stopPublishing;

- (BOOL)stopWatching;

- (BOOL)stopScanning;

- (NSArray *)getCardsWatchedInRange;

- (void)loginWithAuthProvider:(NSString *)authProvider authKey:(NSString *)authKey callback:(void (^)(BOOL result))callback;

- (void)signOutWithCallback:(void (^)(BOOL success))callback;

- (void)skipLogin;

- (void)loadHistory;

- (void)copyAnonymusHistory;

- (void)getUserById:(NSInteger)userId callback:(void (^)(PBUser *user))callback;

- (void)getCurrentUserInfo:(void (^)(PBUser *user))callback;

- (void)saveUser:(PBUser *)user callback:(void (^)(BOOL success))callback;

- (void)linkSocial:(NSString *)socialKey toUser:(PBUser *)user forType:(NSString *)socialType callback:(void (^)(BOOL success))callback;

- (void)loadCardsHistoryWithCallback:(void (^)(NSArray *cards))callback;

- (void)getUserCardsWithCallback:(void (^)(NSArray *cards))callback;

- (void)getCardsForBeaconGuid:(NSString *)guid clBeacon:(CLBeacon *)clBeacon location:(CLLocation *)location callback:(void (^)(NSArray *cards))callback;

- (void)loadDetailForInfoCard:(PBCard *)card callback:(void (^)(PBCard *cardDetail))callback;

- (void)loadDetailForUserCard:(PBCard *)card callback:(void (^)(PBCard *cardDetail))callback;

- (void)loadImageForCardGuid:(NSString *)guid callback:(void (^)(NSData *imageData))callback;

- (void)loadUserBeaconsWithCallback:(void (^)(NSArray *beacons))callback;

- (void)getLinkedBeaconsForCard:(PBCard *)card callback:(void (^)(NSArray *cardBeacons))callback;

- (void)getLinkedCardsForBeacon:(PBBeacon *)beacon callback:(void (^)(NSArray *cards))callback;

- (void)linkCards:(NSArray *)cards toBeacon:(PBBeacon *)beacon callback:(void (^)(BOOL result))callback;

- (void)addNewCard:(PBCard *)card callback:(void (^)(BOOL result, PBCard *addedCard))callback;

- (void)updateCard:(PBCard *)card oldCard:(PBCard *)oldCard callback:(void (^)(BOOL result, PBCard *updatedCard))callback;

- (void)updateBeaconsInCard:(PBCard *)card oldCard:(PBCard *)oldCard callback:(void (^)(PBCard *updated))callback;
- (void)setCard:(PBCard *)card favorite:(BOOL)isFavorite callback:(void (^)(BOOL result))callback;

- (void)acceptCardSharing:(NSString *)shareGuid callback:(void (^)(BOOL result))callback;

- (void)deleteCard:(PBCard *)card callback:(void (^)(BOOL result))callback;

- (void)shareCard:(PBCard *)card toPerson:(PBCardsShare *)sharePerson andSave:(BOOL)save callback:(void (^)(BOOL result, PBCardsShare *cardsShare))callback;

- (void)updateShareCard:(PBCard *)card toPerson:(PBCardsShare *)sharePerson callback:(void (^)(BOOL result, PBCardsShare *cardsShare))callback;

- (void)getBeaconByUid:(NSString *)beaconUid callback:(void (^)(PBBeacon *beacon))callback;

- (void)addBeacon:(PBBeacon *)beacon callback:(void (^)(BOOL success))callback;

- (void)updateBeacon:(PBBeacon *)beacon callback:(void (^)(BOOL success))callback;

- (void)compareLocalCards:(NSArray *)localCards withWebCards:(NSArray *)webCards result:(void (^)(NSArray *cardsForAdd, NSArray *cardsForDelete, NSArray *cardsForUpdate))result;

- (void)compareLocalBeacons:(NSArray *)localBeacons withWebBeacons:(NSArray *)webBeacons result:(void (^)(NSArray *beaconsForAdd, NSArray *beaconsForDelete, NSArray *beaconsForUpdate))result;


- (void)compareOldUids:(NSArray *)oldUids withNewUids:(NSArray *)newUids result:(void (^)(NSArray *beaconsForAdd, NSArray *beaconsForDelete))result;
@end