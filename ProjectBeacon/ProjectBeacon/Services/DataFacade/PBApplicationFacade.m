//
// Created by Oleksandr Malyarenko on 12/7/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <TwitterKit/TwitterKit.h>
#import <Google/SignIn.h>
#import "PBApplicationFacade.h"
#import "PBDataAccessManager.h"
#import "PBSettingsManager.h"
#import "PBBluetoothWatcher.h"
#import "PBBluetoothPublisher.h"
#import "PBWebService.h"
#import "PBWebCard.h"
#import "PBWebUser.h"
#import "PBWebUserSocial.h"
#import "PBCardsShare.h"
#import "PBWebUserSocialLinks.h"
#import "PBWebBeacon.h"
#import "PBWebBeaconCard.h"
#import "PBBeaconCard.h"
#import "PBWebCardHistory.h"
#import "PBError.h"


@interface PBApplicationFacade () <PBBluetoothDelegate>


@property (nonatomic, strong) PBDataAccessManager *dataAccessManager;
@property (nonatomic, strong) PBWebService *webService;
@property (nonatomic, strong) PBSettingsManager *settingsManager;
@property (nonatomic, strong) PBBluetoothWatcher *bluetoothWatcher;
@property (nonatomic, strong) PBBluetoothPublisher *bluetoothPublisher;
@property (nonatomic, strong) NSMutableDictionary *cardsForBeaconsInRange;

@end


@implementation PBApplicationFacade {

}


#pragma mark Singleton Methods


+ (id)sharedManager {
    static PBApplicationFacade *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}


- (instancetype)init {
    if (self = [super init]) {
        self.dataAccessManager = [[PBDataAccessManager alloc] init];
        self.webService = [[PBWebService alloc] init];
        self.settingsManager = [PBSettingsManager sharedManager];
        self.bluetoothPublisher = [[PBBluetoothPublisher alloc] init];
        self.bluetoothWatcher = [[PBBluetoothWatcher alloc] init];
        self.bluetoothWatcher.delegate = self;
        self.bluetoothPublisher.delegate = self;
        self.cardsForBeaconsInRange = [NSMutableDictionary dictionary];
        self.userId = self.settingsManager.lastSessionUserId;

        if (self.settingsManager.isWatcherEnabled) {
            [self.bluetoothWatcher startWatching];
        }
        if (self.settingsManager.isPublisherEnabled) {
            [self.bluetoothPublisher startAdvertising];
        }
    }

    return self;
}


#pragma mark - Main methods


- (BOOL)isAnonymus {
    return self.userId == -1;
}


- (BOOL)isFirstLaunch {
    return self.settingsManager.firstLaunch;
}


- (BOOL)needsLogin {
    if (self.settingsManager.lastSessionUserId == kPBDefaultUserId) {
        return YES;
    }
    else {
        self.userId = self.settingsManager.lastSessionUserId;
        [self.webService setupAuthProvider:self.settingsManager.lastSessionUserAuthProvider authKey:self.settingsManager.lastSessionUserToken];
        [self loadHistory];
        return NO;
    }
}


- (void)loginWithAuthProvider:(NSString *)authProvider authKey:(NSString *)authKey callback:(void (^)(BOOL result))callback {
    [self.webService setupAuthProvider:authProvider authKey:authKey];
    self.settingsManager.lastSessionUserAuthProvider = authProvider;
    self.settingsManager.lastSessionUserToken = authKey;
    [self.webService signInWithAccessToken:authKey success:^(PBWebUser *user) {
        if (!user) {
            if (callback) {
                callback(NO);
                return;
            }
        }
        PBUser *localUser = [[PBUser alloc] init];
        [localUser fromWebModel:(id) user];
        if ([authProvider isEqualToString:kFacebookAuthProvider]) {
            localUser.facebookIsLinked = YES;
        }
        else if ([authProvider isEqualToString:kTwitterAuthProvider]) {
            localUser.twitterIsLinked = YES;
        }
        else if ([authProvider isEqualToString:kGoogleAuthProvider]) {
            localUser.gPlusIsLinked = YES;
        }

        if (callback) {
            callback(YES);
        }
        self.userId = localUser.userId;
        self.settingsManager.lastSessionUserId = self.userId;
        [self.bluetoothPublisher setupPublisher];
        [self.dataAccessManager getUserById:self.userId callback:^(PBUser *userInDb) {
            if (userInDb) {
                userInDb.fullName = localUser.fullName;
                userInDb.email = localUser.email;
                userInDb.userPicture = localUser.userPicture;
                userInDb.facebookIsLinked = localUser.facebookIsLinked;
                userInDb.twitterIsLinked = localUser.twitterIsLinked;
                userInDb.gPlusIsLinked = localUser.gPlusIsLinked;
                [self.dataAccessManager updateUser:userInDb];
            }
            else {
                [self.dataAccessManager addUser:localUser];
            }
        }];
        [self loadHistory];
        [self.bluetoothWatcher stopWatching];
        [self.cardsForBeaconsInRange removeAllObjects];
        [self.bluetoothWatcher startWatching];
    }                              failure:^(NSError *error) {
        if (callback) {
            callback(NO);
        }
        [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:error];
    }];
}


- (void)signOutWithCallback:(void (^)(BOOL success))callback {
    [self.webService signOutWithSuccess:^(BOOL success) {
        if ([self.settingsManager.lastSessionUserAuthProvider isEqualToString:kFacebookAuthProvider]) {

            [[FBSDKLoginManager new] logOut];
            if ([FBSDKAccessToken currentAccessToken]) {
                [FBSDKAccessToken setCurrentAccessToken:nil];
                [FBSDKProfile setCurrentProfile:nil];
            }
        }
        else if ([self.settingsManager.lastSessionUserAuthProvider isEqualToString:kTwitterAuthProvider]) {
            [[Twitter sharedInstance] logOut];
        }
        else if ([self.settingsManager.lastSessionUserAuthProvider isEqualToString:kGoogleAuthProvider]) {
            [[GIDSignIn sharedInstance] signOut];
        }
        self.settingsManager.lastSessionUserId = kPBDefaultUserId;
        self.settingsManager.lastSessionUserAuthProvider = nil;
        self.settingsManager.lastSessionUserToken = nil;
        [self.bluetoothWatcher stopWatching];
        [self.bluetoothPublisher stopAdvertising];
        [self.cardsForBeaconsInRange removeAllObjects];

        if (callback) {
            callback(YES);
        }
    }                           failure:^(NSError *webServiceError) {
        if (callback) {
            callback(NO);
        }
    }];

}


- (void)skipLogin {
    [self.webService setupAuthProvider:nil authKey:nil];
    self.userId = kPBDefaultUserId;
    self.settingsManager.lastSessionUserId = kPBDefaultUserId;
    [self.bluetoothWatcher stopWatching];
    [self.cardsForBeaconsInRange removeAllObjects];
    [self.bluetoothWatcher startWatching];
    [self.bluetoothPublisher stopAdvertising];
    [self.dataAccessManager cleanAnonymusData];
}


- (void)loadHistory {
    __weak PBApplicationFacade *weakSelf = self;
    [self.webService loadHistoryWithSuccess:^(NSArray *cards) {
        [cards enumerateObjectsUsingBlock:^(PBWebCardHistory *webCardHistory, NSUInteger index, BOOL *stop) {
            [weakSelf.webService getDetailForCardGuid:webCardHistory.cardGuid success:^(PBWebCard *webCard) {
                __block PBCard *newCard = [[PBCard alloc] init];
                [newCard fromWebModel:webCard];
                newCard.isFavourite = webCardHistory.isFavorite;
                newCard.visitDate = [NSDate dateWithTimeIntervalSince1970:webCardHistory.received];
                [newCard.vCards enumerateObjectsUsingBlock:^(PBVCard *vCard, NSUInteger index, BOOL *stop) {
                    vCard.cardId = newCard.cardId;
                }];
                [weakSelf.webService getImageForCardGuid:newCard.cardId success:^(NSData *imageData) {
                    if (imageData && imageData.length > 0) {
                        newCard.logo = imageData;
                        newCard.shortInfo = NO;
                    }
                    [weakSelf.dataAccessManager cardExist:newCard callback:^(BOOL exist, PBCard *cardInDb) {
                        if (exist) {
                            [weakSelf.dataAccessManager updateCard:newCard];
                        }
                        else {
                            [weakSelf.dataAccessManager addCard:newCard];
                        }
                        [weakSelf.dataAccessManager cardHistoryExist:newCard.cardId forUser:weakSelf.userId callback:^(BOOL cardHistoryExist, PBCardHistory *cardHistory) {
                            if (exist) {
                                cardHistory.isFavourite = newCard.isFavourite;
                                cardHistory.visitDate = newCard.visitDate;
                                [weakSelf.dataAccessManager updateCardHistory:cardHistory forUser:weakSelf.userId];
                            }
                            else {
                                PBCardHistory *newCardHistory = [[PBCardHistory alloc] init];
                                newCardHistory.cardId = webCardHistory.cardGuid;
                                newCardHistory.isFavourite = webCardHistory.isFavorite;
                                newCardHistory.visitDate = [NSDate dateWithTimeIntervalSince1970:webCardHistory.received];
                                [weakSelf.dataAccessManager addCardHistory:newCardHistory toUser:weakSelf.userId];
                            }
                        }];
                    }];
                }                                failure:^(NSError *getImageError) {
                    [weakSelf.delegate applicationFacade:weakSelf didFailRetrievingInformationFromServiceWithError:getImageError];
                }];
            }                                 failure:^(NSError *webServiceError) {
                [weakSelf.delegate applicationFacade:weakSelf didFailRetrievingInformationFromServiceWithError:webServiceError];
            }];
        }];
    }                               failure:^(NSError *webServiceError) {
        [weakSelf.delegate applicationFacade:weakSelf didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (void)copyAnonymusHistory {
    [self.dataAccessManager copyAnonymusUserHistoryToUser:self.userId];
}


- (void)getUserById:(NSInteger)userId callback:(void (^)(PBUser *user))callback {
    [self.dataAccessManager getUserById:userId callback:^(PBUser *user) {
        if (!user) {
            if (callback) {
                callback(nil);
            }
            return;
        }
        if (callback) {
            callback(user);
        }

        [self.webService getUserById:self.userId success:^(PBWebUser *webUser) {
            __block PBUser *localUser = [[PBUser alloc] init];
            [localUser fromWebModel:(id) webUser];
            user.fullName = localUser.fullName;
            user.email = localUser.email;
            user.userPicture = localUser.userPicture;
            if (callback) {
                callback(user);
            }
            [self.dataAccessManager updateUser:user];

        }                    failure:^(NSError *webServiceError) {
            [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
        }];
    }];

}


- (void)getCurrentUserInfo:(void (^)(PBUser *user))callback {
    [self.dataAccessManager getUserById:self.userId callback:^(PBUser *user) {
        if (!user || user.userId == kPBDefaultUserId) {
            if (callback) {
                callback(nil);
            }
            return;
        }
        if (callback) {
            callback(user);
        }
        [self.webService getUserById:self.userId success:^(PBWebUser *webUser) {
            __block PBUser *localUser = [[PBUser alloc] init];
            [localUser fromWebModel:(id) webUser];
            user.fullName = localUser.fullName;
            user.email = localUser.email;
            user.userPicture = localUser.userPicture;
            [self.webService getSocial:webUser success:^(PBWebUserSocial *result) {
                user.facebookIsLinked = result.facebook;
                user.twitterIsLinked = result.twitter;
                user.gPlusIsLinked = result.google;

                if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveUpdatedUserInfo:)]) {
                    [self.delegate applicationFacade:self didReceiveUpdatedUserInfo:user];
                }
                [self.dataAccessManager updateUser:user];
            }                  failure:^(NSError *webServiceError) {
                [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
            }];

        }                    failure:^(NSError *webServiceError) {
            [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
        }];

    }];

}


- (void)saveUser:(PBUser *)user callback:(void (^)(BOOL success))callback {
    PBWebUser *webUser = [[PBWebUser alloc] init];
    [webUser fromLocalModel:user];
    [self.webService updatetUser:webUser success:^(BOOL result) {
        if (callback) {
            callback(result);
        }
        if (result) {
            [self.dataAccessManager updateUser:user];
        }
    }                    failure:^(NSError *webServiceError) {
        [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (void)linkSocial:(NSString *)socialKey toUser:(PBUser *)user forType:(NSString *)socialType callback:(void (^)(BOOL success))callback {
    PBWebUserSocialLinks *socialLinks = [[PBWebUserSocialLinks alloc] init];
    if ([socialType isEqualToString:kFacebookAuthProvider]) {
        socialLinks.facebook = socialKey;
    }
    else if ([socialType isEqualToString:kTwitterAuthProvider]) {
        socialLinks.twitter = socialKey;
    }
    else if ([socialType isEqualToString:kGoogleAuthProvider]) {
        socialLinks.google = socialKey;
    }
    [self.webService linkSocial:socialLinks success:^(PBWebUserSocial *result) {
        if (result) {
            BOOL linked = NO;
            if ([socialType isEqualToString:kFacebookAuthProvider]) {
                user.facebookIsLinked = result.facebook;
                linked = result.facebook;
            }
            else if ([socialType isEqualToString:kTwitterAuthProvider]) {
                user.twitterIsLinked = result.twitter;
                linked = result.twitter;
            }
            else if ([socialType isEqualToString:kGoogleAuthProvider]) {
                user.gPlusIsLinked = result.google;
                linked = result.google;
            }
            if (callback) {
                callback(linked);
            }

            [self.dataAccessManager updateUser:user];
        }
    }                   failure:^(NSError *webServiceError) {
        [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (void)loadCardsHistoryWithCallback:(void (^)(NSArray *cards))callback {
    [self.dataAccessManager getAllInfoCards:self.userId callback:^(NSArray *cards) {
        if (callback) {
            callback(cards);
        }
        for (PBCard *card in cards) {
            [self loadDetailForInfoCard:card callback:nil];
        }
    }];

}


- (void)getUserCardsWithCallback:(void (^)(NSArray *cards))callback {
    __block NSMutableArray *localCards = [NSMutableArray array];
    [self.dataAccessManager getAllUserCards:self.userId callback:^(NSArray *cards) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_group_t group = dispatch_group_create();
            for (PBCard *card in cards) {
                dispatch_group_enter(group);
                [self.dataAccessManager getDetailsForCard:card isUserCard:YES callback:^(PBCard *detailCard) {
                    [localCards addObject:detailCard];
                    dispatch_group_leave(group);
                }];
            }
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) {
                    callback(localCards);
                }
            });

            [self.webService getUserCardsWithSuccess:^(NSArray *webCards) {
                NSArray *results = [self mapToLocalCards:webCards];
                if (!results) {
                    return;
                }
                [self compareLocalCards:localCards withWebCards:results result:^(NSArray *cardsForAdd, NSArray *cardsForDelete, NSArray *cardsForUpdate) {
                    if (cardsForDelete.count > 0 || cardsForAdd.count > 0 || cardsForUpdate.count > 0) {
                        if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveUpdatedUserCards:)]) {
                            [self.delegate applicationFacade:self didReceiveUpdatedUserCards:results];
                        }
                    }
                    for (PBCard *deleteCard in cardsForDelete) {
                        [self.dataAccessManager deleteCard:deleteCard fromUser:self.userId];
                    }
                    for (PBCard *addCard in cardsForAdd) {
                        [addCard.vCards enumerateObjectsUsingBlock:^(PBVCard *vCard, NSUInteger index, BOOL *stop) {
                            vCard.cardId = addCard.cardId;
                        }];
                        [self.dataAccessManager addCard:addCard forUser:self.userId];
                        [self getUsersForShares:addCard.cardShare callback:^(NSArray *shares){
                            addCard.cardShare = shares;
                            [self.dataAccessManager updateShares:shares forCardId:addCard.cardId];
                        }];
                        [self getLinkedBeaconsForCard:addCard callback:^(NSArray *beacons) {
                            addCard.beacons = beacons;
                            if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailCardInfo:)]) {
                                [self.delegate applicationFacade:self didReceiveDetailCardInfo:addCard];
                            }
                        }];
                    }
                    for (PBCard *updateCard in cardsForUpdate) {
                        [updateCard.vCards enumerateObjectsUsingBlock:^(PBVCard *vCard, NSUInteger index, BOOL *stop) {
                            vCard.cardId = updateCard.cardId;
                        }];
                        [self.dataAccessManager updateCard:updateCard forUser:self.userId];
                        [self getUsersForShares:updateCard.cardShare callback:^(NSArray *shares){
                            updateCard.cardShare = shares;
                            [self.dataAccessManager updateShares:shares forCardId:updateCard.cardId];
                        }];
                        [self getLinkedBeaconsForCard:updateCard callback:^(NSArray *beacons) {
                            updateCard.beacons = beacons;
                            if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailCardInfo:)]) {
                                [self.delegate applicationFacade:self didReceiveDetailCardInfo:updateCard];
                            }
                        }];
                    }
                }];

            }                                failure:^(NSError *webServiceError) {
                if (callback) {
                    callback(nil);
                }
                [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
            }];
        });
    }];

}


- (void)getUsersForShares:(NSArray *)shares callback:(void (^)(NSArray *updatedShares))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        [shares enumerateObjectsUsingBlock:^(PBCardsShare *share, NSUInteger index, BOOL *stop) {
            dispatch_group_enter(group);
            if (share.userId != -1) {
                [self.webService getUserById:share.userId success:^(PBWebUser *webUser) {
                    PBUser *user = [[PBUser alloc] init];
                    [user fromWebModel:webUser];
                    [self.dataAccessManager updateUser:user];
                    share.name = user.fullName;
                    share.email = user.email;
                    share.photo = user.userPicture;
                    dispatch_group_leave(group);
                }                    failure:^(NSError *webServiceError) {
                    dispatch_group_leave(group);
                }];
            }
        }];

        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(shares);
            }
        });
    });
}


- (void)getCardsForBeaconGuid:(NSString *)guid clBeacon:(CLBeacon *)clBeacon location:(CLLocation *)location callback:(void (^)(NSArray *cards))callback {
    __block NSMutableArray *localCards = [NSMutableArray array];
    [self.webService getCardsByBeaconGuid:guid success:^(NSArray *webCards) {
        NSArray *results = [self mapToLocalCards:webCards];
        if (callback) {
            callback(results);
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_group_t group = dispatch_group_create();
            for (PBCard *card in [results mutableCopy]) {
                card.shortInfo = YES;
                [card.vCards enumerateObjectsUsingBlock:^(PBVCard *vCard, NSUInteger index, BOOL *stop) {
                    vCard.cardId = card.cardId;
                }];
                dispatch_group_enter(group);
                [self.dataAccessManager cardExist:card callback:^(BOOL exist, PBCard *existedCard) {
                    if (exist) {
                        if (card.version != existedCard.version) {
                            [self.dataAccessManager updateCard:card];
                        }
                    }
                    else {
                        [self.dataAccessManager addCard:card];
                    }

                    [self.dataAccessManager cardHistoryExist:card.cardId forUser:self.userId callback:^(BOOL cardHistoryExist, PBCardHistory *cardHistory) {
                        if (cardHistoryExist) {
                            existedCard.isFavourite = cardHistory.isFavourite;
                            cardHistory.visitDate = [NSDate date];
                            if(location){
                                if(clBeacon.accuracy == -1){
                                    cardHistory.distance = (pow(10, (-59.0 - clBeacon.rssi) / 10) < cardHistory.distance) ? pow(10, (-59.0 - clBeacon.rssi) / 10) : cardHistory.distance;
                                }
                                else{
                                    cardHistory.distance = (clBeacon.accuracy < cardHistory.distance || cardHistory.distance == 0) ? clBeacon.accuracy : cardHistory.distance;
                                }
                                cardHistory.latitude = location.coordinate.latitude;
                                cardHistory.longitude = location.coordinate.longitude;
                            }
                            [self.dataAccessManager updateCardHistory:cardHistory forUser:self.userId];
                        }
                        else {
                            PBCardHistory *newCardHistory = [[PBCardHistory alloc] init];
                            newCardHistory.cardId = card.cardId;
                            newCardHistory.visitDate = [NSDate date];
                            newCardHistory.isFavourite = NO;
                            if(location){
                                if(clBeacon.accuracy == -1){
                                    newCardHistory.distance = pow(10, (-59.0 - clBeacon.rssi) / 10);
                                }
                                else{
                                    newCardHistory.distance = clBeacon.accuracy;
                                }
                                newCardHistory.latitude = location.coordinate.latitude;
                                newCardHistory.longitude = location.coordinate.longitude;
                            }
                            [self.dataAccessManager addCardHistory:newCardHistory toUser:self.userId];
                        }
                        [localCards addObject:existedCard ? existedCard : card];
                        dispatch_group_leave(group);
                        if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailScanCardInfo:)]) {
                            [self.delegate applicationFacade:self didReceiveDetailScanCardInfo:existedCard];
                        }
                    }];

                    if (card.version != existedCard.version) {
                        [self.webService getDetailForCardGuid:card.cardId success:^(PBWebCard *webCard) {
                            __block PBCard *newCard = [[PBCard alloc] init];
                            [newCard fromWebModel:webCard];
                            newCard.isFavourite = card.isFavourite;
                            [newCard.vCards enumerateObjectsUsingBlock:^(PBVCard *vCard, NSUInteger index, BOOL *stop) {
                                vCard.cardId = newCard.cardId;
                            }];
                            if (!card.shortInfo && card.version == newCard.version) {
                                return;
                            }
                            if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailScanCardInfo:)]) {
                                [self.delegate applicationFacade:self didReceiveDetailScanCardInfo:newCard];
                            }
                            [self.dataAccessManager updateCard:newCard];
                            [self loadImageForCardGuid:newCard.cardId callback:^(NSData *imageData) {
                                if (imageData && imageData.length > 0) {
                                    newCard.logo = imageData;
                                    newCard.shortInfo = NO;
                                    [self.dataAccessManager updateCard:newCard];
                                }
                                if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailScanCardInfo:)]) {
                                    [self.delegate applicationFacade:self didReceiveDetailScanCardInfo:newCard];
                                }
                            }];
                        }                             failure:^(NSError *webServiceError) {
                            [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
                        }];
                    }
                }];
            }
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (localCards.count > 0 && callback) {
                    callback(localCards);
                }
            });
        });
    }                             failure:^(NSError *webServiceError) {
        if (callback) {
            callback(nil);
        }
        [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (void)loadDetailForInfoCard:(PBCard *)card callback:(void (^)(PBCard *cardDetail))callback {
    [self.dataAccessManager getDetailsForCard:card isUserCard:NO callback:^(PBCard *detailCard) {
        if (callback) {
            callback(detailCard);
        }
        [self.webService getDetailForCardGuid:card.cardId success:^(PBWebCard *webCard) {
            if(!webCard){
                return;
            }
            __block PBCard *newCard = [[PBCard alloc] init];
            [newCard fromWebModel:webCard];
            newCard.isFavourite = card.isFavourite;
            [newCard.vCards enumerateObjectsUsingBlock:^(PBVCard *vCard, NSUInteger index, BOOL *stop) {
                vCard.cardId = newCard.cardId;
            }];
            if (!card.shortInfo && card.version == newCard.version) {
                return;
            }
            if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailCardInfo:)]) {
                [self.delegate applicationFacade:self didReceiveDetailCardInfo:newCard];
            }
            [self.dataAccessManager updateCard:newCard];
            [self loadImageForCardGuid:newCard.cardId callback:^(NSData *imageData) {
                if (imageData && imageData.length > 0) {
                    newCard.logo = imageData;
                    newCard.shortInfo = NO;
                    [self.dataAccessManager updateCard:newCard];
                }
                if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailCardInfo:)]) {
                    [self.delegate applicationFacade:self didReceiveDetailCardInfo:newCard];
                }
            }];
        }                             failure:^(NSError *webServiceError) {
            [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
        }];
    }];
}


- (void)loadDetailForUserCard:(PBCard *)card callback:(void (^)(PBCard *cardDetail))callback {
    [self.dataAccessManager getDetailsForCard:card isUserCard:YES callback:^(PBCard *detailCard) {
        if (callback) {
            callback(detailCard);
        }
        [self.webService getCardByGuid:card.cardId success:^(PBWebCard *webCard) {
            __block PBCard *newCard = [[PBCard alloc] init];
            [newCard fromWebModel:webCard];
            if(!newCard){
                return;
            }
            [newCard.vCards enumerateObjectsUsingBlock:^(PBVCard *vCard, NSUInteger index, BOOL *stop) {
                vCard.cardId = newCard.cardId;
            }];
            if (!card.shortInfo && card.version == newCard.version) {
                return;
            }
            if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailCardInfo:)]) {
                [self.delegate applicationFacade:self didReceiveDetailCardInfo:newCard];
            }
            [self.dataAccessManager updateCard:newCard forUser:self.userId];
            [self getLinkedBeaconsForCard:newCard callback:nil];
            [self.dataAccessManager updateShares:newCard.cardShare forCardId:newCard.cardId];
        }                      failure:^(NSError *webServiceError) {
            [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
        }];
    }];
}


- (void)loadImageForCardGuid:(NSString *)guid callback:(void (^)(NSData *imageData))callback {
    [self.webService getImageForCardGuid:guid success:callback failure:^(NSError *webServiceError) {
        [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (void)loadUserBeaconsWithCallback:(void (^)(NSArray *beacons))callback {
    __weak PBApplicationFacade *weakSelf = self;
    [self.dataAccessManager getAllBeaconsForUser:self.userId withCallback:^(NSArray *beaconsInDb) {
        if (beaconsInDb.count > 0) {
            if (callback) {
                callback(beaconsInDb);
            }
        }
        else {
            if (callback) {
                callback(nil);
            }
        }
        [weakSelf.webService getAllUserBeaconsWithSuccess:^(NSArray *webBeacons) {
            __block NSMutableArray *beacons = [NSMutableArray array];
            [webBeacons enumerateObjectsUsingBlock:^(PBWebBeacon *webBeacon, NSUInteger index, BOOL *stop) {
                PBBeacon *beacon = [[PBBeacon alloc] init];
                [beacon fromWebModel:(id) webBeacon];
                [beacons addObject:beacon];
            }];
            if ([weakSelf.delegate respondsToSelector:@selector(applicationFacade: didReceiveUpdatedUserBeacons:)]) {
                [weakSelf.delegate applicationFacade:weakSelf didReceiveUpdatedUserBeacons:beacons];
            }
            [weakSelf compareLocalBeacons:beaconsInDb withWebBeacons:beacons result:^(NSArray *beaconsForAdd, NSArray *beaconsForDelete, NSArray *beaconsForUpdate) {
                [beaconsForAdd enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
                    [weakSelf.dataAccessManager addBeacon:beacon];
                }];
                [beaconsForUpdate enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
                    [weakSelf.dataAccessManager updateBeacon:beacon];
                }];
                [beaconsForDelete enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
                    [weakSelf.dataAccessManager deleteBeacon:beacon];
                }];
            }];

        }                                         failure:^(NSError *webServiceError) {
            [weakSelf.delegate applicationFacade:weakSelf didFailRetrievingInformationFromServiceWithError:webServiceError];
        }];
    }];

}


- (void)getLinkedBeaconsForCard:(PBCard *)card callback:(void (^)(NSArray *cardBeacons))callback {
    __weak PBApplicationFacade *weakSelf = self;
    [self.webService getBeaconsForCardGuid:card.cardId success:^(NSArray *webBeacons) {
        __block NSMutableArray *beacons = [NSMutableArray array];
        [webBeacons enumerateObjectsUsingBlock:^(PBWebBeacon *webBeacon, NSUInteger index, BOOL *stop) {
            PBBeacon *beacon = [[PBBeacon alloc] init];
            [beacon fromWebModel:(id) webBeacon];
            [beacon.cards enumerateObjectsUsingBlock:^(PBBeaconCard *beaconCard, NSUInteger index1, BOOL *stop1){
                if([beaconCard.cardGuid isEqualToString:card.cardId]){
                    beacon.state = beaconCard.isActive;
                    *stop1 = YES;
                }
            }];
            [beacons addObject:beacon];
        }];
        [weakSelf compareLocalBeacons:card.beacons withWebBeacons:beacons result:^(NSArray *beaconsForAdd, NSArray *beaconsForDelete, NSArray *beaconsForUpdate) {
            [beaconsForAdd enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
                [weakSelf.dataAccessManager addBeacon:beacon];
            }];
            [beaconsForUpdate enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
                [weakSelf.dataAccessManager updateBeacon:beacon];
            }];
            [beaconsForDelete enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
                [weakSelf.dataAccessManager deleteBeacon:beacon];
            }];
            card.beacons = beacons;
            if (callback) {
                callback(beacons);
            }
            if ([weakSelf.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailCardInfo:)]) {
                [weakSelf.delegate applicationFacade:weakSelf didReceiveDetailCardInfo:card];
            }
        }];
    }                              failure:^(NSError *webServiceError) {
        if (callback) {
            callback(nil);
        }
        [weakSelf.delegate applicationFacade:weakSelf didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (void)getLinkedCardsForBeacon:(PBBeacon *)beacon callback:(void (^)(NSArray *cards))callback {
    __weak PBApplicationFacade *weakSelf = self;
    [self.dataAccessManager getCardsForBeacon:beacon callback:^(NSArray *linkedCards) {
        if (callback) {
            callback(linkedCards);
        }
        for (PBCard *card in linkedCards) {
            [weakSelf.webService getCardByGuid:card.cardId success:^(PBWebCard *webCard) {
                PBCard *updatedCard = [[PBCard alloc] init];
                [updatedCard fromWebModel:webCard];
                updatedCard.isActive = card.isActive;
                if ([updatedCard isEqual:card] && updatedCard.version == card.version) {
                    return;
                }
                [weakSelf.dataAccessManager updateCard:updatedCard forUser:self.userId];
                if ([weakSelf.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailCardInfo:)]) {
                    [weakSelf.delegate applicationFacade:weakSelf didReceiveDetailCardInfo:updatedCard];
                }
            }                          failure:^(NSError *webServiceError) {
                [weakSelf.delegate applicationFacade:weakSelf didFailRetrievingInformationFromServiceWithError:webServiceError];
            }];
        }
    }];
}


- (void)addNewCard:(PBCard *)card callback:(void (^)(BOOL result, PBCard *addedCard))callback {
    __weak PBApplicationFacade *weakSelf = self;
    card.permission = PBCardPermissionOwner;
    PBWebCard *webCard = [[PBWebCard alloc] init];
    [webCard fromLocalModel:card];
    [self.webService insertCard:webCard success:^(PBWebCard *addedCard) {
        __block PBCard *object = [[PBCard alloc] init];
        [object fromWebModel:addedCard];
        object.beacons = card.beacons;
        [object.vCards enumerateObjectsUsingBlock:^(PBVCard *vCard, NSUInteger index, BOOL *stop) {
            vCard.cardId = object.cardId;
        }];
        [weakSelf addSharesToCard:object callback:^(PBCard *added) {
            object = added;
            [weakSelf.dataAccessManager addCard:added forUser:weakSelf.userId];
            [weakSelf addBeaconsToCard:object callback:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) {
                    callback(YES, object);
                }
            });
        }];
    }                   failure:^(NSError *webServiceError) {
        if (callback) {
            callback(NO, nil);
        }
    }];
}


- (void)addBeaconsToCard:(PBCard *)card callback:(void (^)(PBCard *added))callback {
    __weak PBApplicationFacade *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_group_t group = dispatch_group_create();

        [card.beacons enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
            dispatch_group_enter(group);
            NSMutableArray *linkedCards = beacon.cards.count > 0 ? [beacon.cards mutableCopy] : [NSMutableArray array];
            PBBeaconCard *beaconCard = [[PBBeaconCard alloc] init];
            beaconCard.cardGuid = card.cardId;
            beaconCard.isActive = beacon.state;
            [linkedCards addObject:beaconCard];
            beacon.cards = linkedCards;

            [weakSelf getBeaconByUid:beacon.beaconUid callback:^(PBBeacon *beaconFromService) {
                if (beaconFromService) {
                    [weakSelf updateBeacon:beacon callback:nil];
                }
                else {
                    [weakSelf addBeacon:beacon callback:nil];
                }
                dispatch_group_leave(group);
            }];
        }];

        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(card);
            }
        });
    });
}


- (void)addSharesToCard:(PBCard *)card callback:(void (^)(PBCard *added))callback {
    __weak PBApplicationFacade *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_group_t group = dispatch_group_create();

        __block NSMutableArray *shares = [NSMutableArray array];
        [card.cardShare enumerateObjectsUsingBlock:^(PBCardsShare *cardsShare, NSUInteger index, BOOL *stop) {
            dispatch_group_enter(group);
            [weakSelf shareCard:card toPerson:cardsShare andSave:NO callback:^(BOOL result, PBCardsShare *shared) {
                [shares addObject:shared];
                dispatch_group_leave(group);
            }];
        }];

        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            card.cardShare = shares;
            if (callback) {
                callback(card);
            }
        });
    });
}


- (void)updateCard:(PBCard *)card oldCard:(PBCard *)oldCard callback:(void (^)(BOOL result, PBCard *updatedCard))callback {
    __weak PBApplicationFacade *weakSelf = self;
    PBWebCard *webCard = [[PBWebCard alloc] init];
    [webCard fromLocalModel:card];
    [self.webService updateCard:webCard success:^(PBWebCard *updatedCard) {
        __block PBCard *object = [[PBCard alloc] init];
        [object fromWebModel:updatedCard];
        object.beacons = card.beacons;
        [object.vCards enumerateObjectsUsingBlock:^(PBVCard *vCard, NSUInteger index, BOOL *stop) {
            vCard.cardId = object.cardId;
        }];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_group_t group = dispatch_group_create();

            dispatch_group_enter(group);
            [weakSelf updateBeaconsInCard:card oldCard:oldCard callback:^(PBCard *updated) {
                object = updated;
                dispatch_group_leave(group);
            }];
            dispatch_group_enter(group);
            [weakSelf updateSharesInCard:card oldCard:oldCard callback:^(PBCard *updated) {
                object = updated;
                dispatch_group_leave(group);
            }];

            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.dataAccessManager updateCard:object forUser:weakSelf.userId];
                if (callback) {
                    callback(YES, object);
                }
            });
        });
    }                   failure:^(NSError *webServiceError) {
        if (callback) {
            callback(NO, nil);
        }
    }];
}


- (void)updateBeaconsInCard:(PBCard *)card oldCard:(PBCard *)oldCard callback:(void (^)(PBCard *updated))callback {
    __weak PBApplicationFacade *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_group_t group = dispatch_group_create();

        [weakSelf compareOldBeacons:oldCard.beacons withNewBeacons:card.beacons result:^(NSArray *forAdd, NSArray *forDelete, NSArray *forUpdate) {

            [forAdd enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
                dispatch_group_enter(group);
                NSMutableArray *linkedCards = beacon.cards.count > 0 ? [beacon.cards mutableCopy] : [NSMutableArray array];
                PBBeaconCard *beaconCard = [[PBBeaconCard alloc] init];
                beaconCard.cardGuid = card.cardId;
                beaconCard.isActive = beacon.state;
                [linkedCards addObject:beaconCard];
                beacon.cards = linkedCards;
                beacon.linkedCardsCount = linkedCards.count;

                [weakSelf getBeaconByUid:beacon.beaconUid callback:^(PBBeacon *beaconFromService) {
                    if (beaconFromService) {
                        [weakSelf updateBeacon:beacon callback:^(BOOL success) {
                            if (!success) {
                                __block NSUInteger beaconIndex;
                                [card.beacons enumerateObjectsUsingBlock:^(PBBeacon *beaconInCards, NSUInteger index1, BOOL *stop1) {
                                    if ([beaconInCards isEqual:beacon]) {
                                        beaconIndex = index1;
                                        *stop1 = YES;
                                    }
                                }];
                                if (card.beacons.count > 0) {
                                    NSMutableArray *temp = [card.beacons mutableCopy];
                                    [temp removeObjectAtIndex:beaconIndex];
                                    card.beacons = temp;
                                }
                            }
                            dispatch_group_leave(group);
                        }];
                    }
                    else {
                        [weakSelf addBeacon:beacon callback:^(BOOL success) {
                            if (!success) {
                                __block NSUInteger beaconIndex;
                                [card.beacons enumerateObjectsUsingBlock:^(PBBeacon *beaconInCards, NSUInteger index1, BOOL *stop1) {
                                    if ([beaconInCards isEqual:beacon]) {
                                        beaconIndex = index1;
                                        *stop1 = YES;
                                    }
                                }];
                                if (card.beacons.count > 0) {
                                    NSMutableArray *temp = [card.beacons mutableCopy];
                                    [temp removeObjectAtIndex:beaconIndex];
                                    card.beacons = temp;
                                }
                            }
                            dispatch_group_leave(group);
                        }];
                    }
                }];
            }];

            [forUpdate enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
                dispatch_group_enter(group);
                NSMutableArray *linkedCards = beacon.cards.count > 0 ? [beacon.cards mutableCopy] : [NSMutableArray array];
                PBBeaconCard *beaconCard = [[PBBeaconCard alloc] init];
                beaconCard.cardGuid = card.cardId;
                beaconCard.isActive = beacon.state;
                if([linkedCards containsObject:beaconCard]){
                    linkedCards[[linkedCards indexOfObject:beaconCard ]]= beaconCard;
                }
                beacon.cards = linkedCards;
                beacon.linkedCardsCount = linkedCards.count;

                [weakSelf getBeaconByUid:beacon.beaconUid callback:^(PBBeacon *beaconFromService) {
                    if (beaconFromService) {
                        [weakSelf updateBeacon:beacon callback:^(BOOL success) {
                            if (!success) {
                                __block NSUInteger beaconIndex;
                                [card.beacons enumerateObjectsUsingBlock:^(PBBeacon *beaconInCards, NSUInteger index1, BOOL *stop1) {
                                    if ([beaconInCards isEqual:beacon]) {
                                        beaconIndex = index1;
                                        *stop1 = YES;
                                    }
                                }];
                                if (card.beacons.count > 0) {
                                    __block NSUInteger oldBeaconIndex;
                                    [oldCard.beacons enumerateObjectsUsingBlock:^(PBBeacon *beaconInCards, NSUInteger index1, BOOL *stop1) {
                                        if ([beaconInCards isEqual:beacon]) {
                                            oldBeaconIndex = index1;
                                            *stop1 = YES;
                                        }
                                    }];
                                    NSMutableArray *temp = [card.beacons mutableCopy];
                                    temp[beaconIndex] = oldCard.beacons[oldBeaconIndex];
                                    card.beacons = temp;
                                }
                            }
                            dispatch_group_leave(group);
                        }];
                    }
                    else {
                        [weakSelf addBeacon:beacon callback:^(BOOL success) {
                            if (!success) {
                                __block NSUInteger beaconIndex;
                                [card.beacons enumerateObjectsUsingBlock:^(PBBeacon *beaconInCards, NSUInteger index1, BOOL *stop1) {
                                    if ([beaconInCards isEqual:beacon]) {
                                        beaconIndex = index1;
                                        *stop1 = YES;
                                    }
                                }];
                                if (card.beacons.count > 0) {
                                    __block NSUInteger oldBeaconIndex;
                                    [oldCard.beacons enumerateObjectsUsingBlock:^(PBBeacon *beaconInCards, NSUInteger index1, BOOL *stop1) {
                                        if ([beaconInCards isEqual:beacon]) {
                                            oldBeaconIndex = index1;
                                            *stop1 = YES;
                                        }
                                    }];
                                    NSMutableArray *temp = [card.beacons mutableCopy];
                                    temp[beaconIndex] = oldCard.beacons[oldBeaconIndex];
                                    card.beacons = temp;
                                }
                            }
                            dispatch_group_leave(group);
                        }];
                    }
                }];
            }];
            [forDelete enumerateObjectsUsingBlock:^(PBBeacon *beacon, NSUInteger index, BOOL *stop) {
                dispatch_group_enter(group);
                NSMutableArray *linkedCards = beacon.cards.count > 0 ? [beacon.cards mutableCopy] : [NSMutableArray array];
                __block NSUInteger beaconCardIndex = NSUIntegerMax;
                [linkedCards enumerateObjectsUsingBlock:^(PBBeaconCard *beaconCard, NSUInteger index1, BOOL *stop1) {
                    if ([beaconCard.cardGuid isEqualToString:card.cardId]) {
                        beaconCardIndex = index1;
                        *stop1 = YES;
                    }
                }];
                if(beaconCardIndex != NSUIntegerMax){
                    [linkedCards removeObjectAtIndex:beaconCardIndex];
                }
                beacon.cards = linkedCards;
                beacon.linkedCardsCount = linkedCards.count;

                [weakSelf updateBeacon:beacon callback:nil];
                dispatch_group_leave(group);
            }];
        }];

        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(card);
            }
        });
    });
}


- (void)updateSharesInCard:(PBCard *)card oldCard:(PBCard *)oldCard callback:(void (^)(PBCard *updated))callback {
    __weak PBApplicationFacade *weakSelf = self;
    __block NSMutableArray *shares = [NSMutableArray array];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        [weakSelf compareOldShares:oldCard.cardShare withNewShares:card.cardShare result:^(NSArray *forAdd, NSArray *forDelete, NSArray *forUpdate) {
            [forAdd enumerateObjectsUsingBlock:^(PBCardsShare *cardsShare, NSUInteger index, BOOL *stop) {
                dispatch_group_enter(group);
                [weakSelf shareCard:card toPerson:cardsShare andSave:NO callback:^(BOOL result, PBCardsShare *shared) {
                    [shares addObject:shared];
                    dispatch_group_leave(group);
                }];
            }];
            [forUpdate enumerateObjectsUsingBlock:^(PBCardsShare *cardsShare, NSUInteger index, BOOL *stop) {
                dispatch_group_enter(group);
                [weakSelf updateShareCard:card toPerson:cardsShare callback:^(BOOL result, PBCardsShare *shared) {
                    [shares addObject:shared];
                    dispatch_group_leave(group);
                }];
            }];
            [forDelete enumerateObjectsUsingBlock:^(PBCardsShare *cardsShare, NSUInteger index, BOOL *stop) {
                dispatch_group_enter(group);
                [weakSelf deleteShareCard:card forPerson:cardsShare callback:^(BOOL result) {
                    dispatch_group_leave(group);
                }];
            }];
        }];

        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (shares.count > 0) {
                card.cardShare = shares;
            }

            [weakSelf.dataAccessManager updateCard:card forUser:weakSelf.userId];
            if (callback) {
                callback(card);
            }
        });
    });
}


- (void)linkCards:(NSArray *)cards toBeacon:(PBBeacon *)beacon callback:(void (^)(BOOL result))callback {
    __weak PBApplicationFacade *weakSelf = self;
    PBWebBeacon *webBeacon = [[PBWebBeacon alloc] init];
    [webBeacon fromLocalModel:beacon];
    __block NSMutableArray *linkedCards = [NSMutableArray array];
    [cards enumerateObjectsUsingBlock:^(PBCard *card, NSUInteger index, BOOL *stop) {
        PBWebBeaconCard *webBeaconCard = [[PBWebBeaconCard alloc] init];
        webBeaconCard.cardGuid = card.cardId;
        webBeaconCard.isActive = card.isActive;
        [linkedCards addObject:webBeaconCard];
    }];
    webBeacon.cards = linkedCards;
    [self.webService updateBeacon:webBeacon success:^(PBWebBeacon *updatedBeacon) {
        if (updatedBeacon) {
            PBBeacon *localBeacon = [[PBBeacon alloc] init];
            [localBeacon fromWebModel:updatedBeacon];
            [weakSelf.dataAccessManager updateBeacon:localBeacon];

            if (callback) {
                callback(YES);
            }
        }
        else {
            if (callback) {
                callback(NO);
            }
        }
    }                     failure:^(NSError *webServiceError) {
        [weakSelf.delegate applicationFacade:weakSelf didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (void)setCard:(PBCard *)card favorite:(BOOL)isFavorite callback:(void (^)(BOOL result))callback {
    __weak PBApplicationFacade *weakSelf = self;
    if (self.userId == kPBDefaultUserId) {
        NSArray *scanningCards = [self getCardsWatchedInRange];
        [scanningCards enumerateObjectsUsingBlock:^(PBCard *scanningCard, NSUInteger index, BOOL *stop) {
            if ([scanningCard isEqual:card]) {
                scanningCard.isFavourite = isFavorite;
            }
        }];
        [self.dataAccessManager cardHistoryExist:card.cardId forUser:self.userId callback:^(BOOL exist, PBCardHistory *cardHistory) {
            if (exist) {
                cardHistory.isFavourite = isFavorite;
                [weakSelf.dataAccessManager updateCardHistory:cardHistory forUser:self.userId];
                if (callback) {
                    callback(YES);
                }
            }
        }];
    }
    else {
        PBWebCard *webCard = [[PBWebCard alloc] init];
        [webCard fromLocalModel:card];
        [self.webService setFavourite:isFavorite forCard:webCard success:^(BOOL success) {
            NSArray *scanningCards = [weakSelf getCardsWatchedInRange];
            if (success) {
                [scanningCards enumerateObjectsUsingBlock:^(PBCard *scanningCard, NSUInteger index, BOOL *stop) {
                    if ([scanningCard isEqual:card]) {
                        scanningCard.isFavourite = isFavorite;
                    }
                }];
                [weakSelf.dataAccessManager cardHistoryExist:card.cardId forUser:weakSelf.userId callback:^(BOOL exist, PBCardHistory *cardHistory) {
                    if (exist) {
                        cardHistory.isFavourite = isFavorite;
                        [weakSelf.dataAccessManager updateCardHistory:cardHistory forUser:weakSelf.userId];
                    }
                }];
            }
            if (callback) {
                callback(success);
            }
            if ([weakSelf.delegate respondsToSelector:@selector(applicationFacade: didReceiveDetailCardInfo:)]) {
                [weakSelf.delegate applicationFacade:weakSelf didReceiveDetailCardInfo:card];
            }
        }                     failure:^(NSError *webServiceError) {
            if (callback) {
                callback(NO);
            }
            [weakSelf.delegate applicationFacade:weakSelf didFailRetrievingInformationFromServiceWithError:webServiceError];
        }];
    }
}


- (void)acceptCardSharing:(NSString *)shareGuid callback:(void (^)(BOOL result))callback {
    [self.webService acceptCardSharing:shareGuid success:^(BOOL success) {
        if (callback) {
            callback(success);
        }
    }                          failure:^(NSError *webServiceError) {
        if (callback) {
            callback(NO);
        }
        [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (void)deleteCard:(PBCard *)card callback:(void (^)(BOOL result))callback {
    PBWebCard *webCard = [[PBWebCard alloc] init];
    [webCard fromLocalModel:card];
    [self.webService deleteCard:webCard success:^(BOOL success) {
        if (success) {
            [self.dataAccessManager deleteCard:card fromUser:self.userId];
        }
        if (callback) {
            callback(success);
        }
    }                   failure:^(NSError *webServiceError) {
        if (callback) {
            callback(NO);
        }
        [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];

}


- (void)shareCard:(PBCard *)card toPerson:(PBCardsShare *)sharePerson andSave:(BOOL)save callback:(void (^)(BOOL result, PBCardsShare *cardsShare))callback {
    PBWebCard *webCard = [[PBWebCard alloc] init];
    [webCard fromLocalModel:card];
    [self.webService shareCard:webCard toUserByEmail:sharePerson.email withPermission:sharePerson.permission success:^(BOOL success, PBWebCardsShare *webCardsShare) {
        if (success) {
            PBCardsShare *cardsShare = [[PBCardsShare alloc] init];
            [cardsShare fromWebModel:(id) webCardsShare];
            if (save) {
                [self.dataAccessManager addShares:@[cardsShare] toCardId:card.cardId];
            }
            if (callback) {
                callback(success, cardsShare);
            }
        }
    }                  failure:^(NSError *webServiceError) {
        if (callback) {
            callback(NO, nil);
        }
        [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (void)updateShareCard:(PBCard *)card toPerson:(PBCardsShare *)sharePerson callback:(void (^)(BOOL result, PBCardsShare *cardsShare))callback {
    if (sharePerson.userId != -1) {
        [self.webService changePermission:sharePerson.permission forUserId:sharePerson.userId cardGuid:card.cardId success:^(BOOL success, PBWebCardsShare *webCardsShare) {
            PBCardsShare *cardsShare = [[PBCardsShare alloc] init];
            [cardsShare fromWebModel:(id) webCardsShare];
            if (callback) {
                callback(success, cardsShare);
            }
        }                         failure:^(NSError *webServiceError) {
            [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
        }];
    }
    else {
        [self.webService changePermission:sharePerson.permission forShareGuid:sharePerson.shareGuid success:^(BOOL success, PBWebCardsShare *webCardsShare) {
            PBCardsShare *cardsShare = [[PBCardsShare alloc] init];
            [cardsShare fromWebModel:(id) webCardsShare];
            if (callback) {
                callback(success, cardsShare);
            }
        }                         failure:^(NSError *webServiceError) {
            [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
        }];
    }
}


- (void)deleteShareCard:(PBCard *)card forPerson:(PBCardsShare *)sharePerson callback:(void (^)(BOOL result))callback {
    if (sharePerson.userId != -1) {
        [self.webService deleteSharingForUserId:sharePerson.userId cardGuid:card.cardId success:^(BOOL success) {
            [self.dataAccessManager deleteShares:@[sharePerson] forCardId:card.cardId];
        }                               failure:^(NSError *webServiceError) {
            [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
        }];
    }
    else {
        [self.webService deleteSharingForGuid:sharePerson.shareGuid success:^(BOOL success) {
            [self.dataAccessManager deleteShares:@[sharePerson] forCardId:card.cardId];
        }                             failure:^(NSError *webServiceError) {
            [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
        }];
    }
}


- (void)getBeaconByUid:(NSString *)beaconUid callback:(void (^)(PBBeacon *beacon))callback {
    [self.dataAccessManager getBeaconByUid:beaconUid callback:^(PBBeacon *beacon) {
        if (beacon && callback) {
            callback(beacon);
        }
        [self.webService getDetailsForBeaconGuid:beaconUid success:^(PBWebBeacon *webBeacon) {
            if (!webBeacon) {
                return;
            }
            PBBeacon *returnedBeacon = [[PBBeacon alloc] init];
            [returnedBeacon fromWebModel:webBeacon];
            if (beacon.version == returnedBeacon.version) {
                return;
            }
            [self.dataAccessManager beaconExist:returnedBeacon callback:^(BOOL exist) {
                if (!exist) {
                    [self.dataAccessManager addBeacon:returnedBeacon];
                }
                else {
                    [self.dataAccessManager updateBeacon:returnedBeacon];
                }
            }];
            if (callback) {
                callback(returnedBeacon);
            }

        }                                failure:^(NSError *webServiceError) {
            if (callback) {
                callback(nil);
            }
        }];
    }];
}


- (void)addBeacon:(PBBeacon *)beacon callback:(void (^)(BOOL success))callback {
    PBWebBeacon *webBeacon = [[PBWebBeacon alloc] init];
    [webBeacon fromLocalModel:beacon];
    [self.webService insertBeacon:webBeacon success:^(PBWebBeacon *insertedBeacon) {
        PBBeacon *object = [[PBBeacon alloc] init];
        [object fromWebModel:insertedBeacon];
        object.state = beacon.state;
        [self.dataAccessManager addBeacon:object];
        if (callback) {
            callback(YES);
        }
    }                     failure:^(NSError *webServiceError) {
        if (callback) {
            callback(NO);
        }
        [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (void)updateBeacon:(PBBeacon *)beacon callback:(void (^)(BOOL success))callback {
    PBWebBeacon *webBeacon = [[PBWebBeacon alloc] init];
    [webBeacon fromLocalModel:beacon];
    [self.webService updateBeacon:webBeacon success:^(PBWebBeacon *updatedBeacon) {
        PBBeacon *object = [[PBBeacon alloc] init];
        [object fromWebModel:updatedBeacon];
        object.state = beacon.state;
        [self.dataAccessManager updateBeacon:object];
        if (callback) {
            callback(YES);
        }
    }                     failure:^(NSError *webServiceError) {
        if (callback) {
            callback(NO);
        }
        NSRange range = [webServiceError.localizedDescription rangeOfString:@"401"];
        if (range.location != NSNotFound) {
            webServiceError = [NSError errorWithDomain:kPBErrorDomain code:kPBWebserviceBeaconLinkBusyErrorCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBWebserviceBeaconLinkBusyError]}];
        }
        [self.delegate applicationFacade:self didFailRetrievingInformationFromServiceWithError:webServiceError];
    }];
}


- (PBBeacon *)getDeviceAsBeaconInfo {
    [self.bluetoothPublisher setupPublisher];
    PBBeacon *beacon = [[PBBeacon alloc] init];
    beacon.beaconUid = [self.bluetoothPublisher.advertisenmentUUID UUIDString];
    beacon.major = self.bluetoothPublisher.advertisenmentMajor;
    beacon.minor = self.bluetoothPublisher.advertisenmentMinor;
    beacon.power = self.bluetoothPublisher.devicePower;

    return beacon;
}


- (BOOL)isWatching {
    return [self.bluetoothWatcher watcherStatus];
}


- (BOOL)isPublishing {
    return [self.bluetoothPublisher publisherStatus];
}


- (BOOL)startPublishing {
    [self.bluetoothPublisher startAdvertising];
    BOOL status = [self.bluetoothPublisher publisherStatus];
    if (status) {
        self.settingsManager.isPublisherEnabled = YES;
    }
    return status;
}


- (BOOL)startWatching {
    [self.bluetoothWatcher startWatching];
    BOOL status = [self.bluetoothWatcher watcherStatus];
    if (status && self.userId != -1) {
        self.settingsManager.isWatcherEnabled = YES;
    }
    return status;
}


- (BOOL)startScanning {
    [self.bluetoothWatcher startScanning];
    return [self.bluetoothWatcher scannerStatus];
}


- (BOOL)stopScanning {
    [self.bluetoothWatcher stopScanning];
    return [self.bluetoothWatcher scannerStatus];
}


- (NSArray *)getCardsWatchedInRange {
    __block NSMutableArray *results = [NSMutableArray array];
    for (NSArray *array in self.cardsForBeaconsInRange.allValues) {
        [array enumerateObjectsUsingBlock:^(PBCard *card, NSUInteger index, BOOL *stop) {
            if (![results containsObject:card]) {
                [results addObject:card];
            }
        }];
    }
    return results;
}


- (BOOL)stopPublishing {
    [self.bluetoothPublisher stopAdvertising];
    self.settingsManager.isPublisherEnabled = NO;
    return [self.bluetoothPublisher publisherStatus];
}


- (BOOL)stopWatching {
    [self.cardsForBeaconsInRange removeAllObjects];
    [self.bluetoothWatcher stopWatching];
    self.settingsManager.isWatcherEnabled = NO;
    return [self.bluetoothWatcher watcherStatus];
}


#pragma mark - PBBluetoothDelegate methods


- (void)bluetoothDidUpdateBluetoothStatus:(BOOL)status {
    if ([self.delegate respondsToSelector:@selector(applicationFacade: didUpdateBluetoothStatus:)]) {
        [self.delegate applicationFacade:self didUpdateBluetoothStatus:status];
    }
}


- (void)bluetoothWatcher:(PBBluetoothWatcher *)watcher didUpdateBeaconsWatchedInRange:(NSArray *)beacons {
    NSMutableArray *newUids = [NSMutableArray array];
    for (CLBeacon *beacon in beacons) {
        [newUids addObject:[beacon.proximityUUID UUIDString]];
    }
    [self compareOldUids:self.cardsForBeaconsInRange.allKeys withNewUids:newUids result:^(NSArray *arrayForAdd, NSArray *arrayForDelete) {
        if (arrayForAdd.count > 0 || arrayForDelete.count > 0) {
            for (NSString *uid in arrayForDelete) {
                [self.cardsForBeaconsInRange removeObjectForKey:uid];
            }
            for (CLBeacon *beacon in beacons) {
                PBBeacon *localBeacon = [[PBBeacon alloc] initWithCLBeacon:beacon];
                [self getCardsForBeaconGuid:localBeacon.beaconUid clBeacon:beacon location:watcher.currentLocation callback:^(NSArray *cards) {
                    [self processBeacon:localBeacon withCards:cards];
                }];
            }
        }
    }];

}


- (void)processBeacon:(PBBeacon *)localBeacon withCards:(NSArray *)cards {
    NSMutableArray *objects = (NSMutableArray *) self.cardsForBeaconsInRange[localBeacon.beaconUid];
    if (objects) {
        [objects removeAllObjects];
        [objects addObjectsFromArray:cards];

        if ([self.delegate respondsToSelector:@selector(applicationFacade:didReceiveCardsForBeacon:)]) {
            [self.delegate applicationFacade:self didReceiveCardsForBeacon:[self getCardsWatchedInRange]];
        }
    }
    else {
        self.cardsForBeaconsInRange[localBeacon.beaconUid] = cards;

        if ([self.delegate respondsToSelector:@selector(applicationFacade:didReceiveCardsForBeacon:)]) {
            [self.delegate applicationFacade:self didReceiveCardsForBeacon:[self getCardsWatchedInRange]];
        }
    }
}


- (void)bluetoothWatcher:(PBBluetoothWatcher *)watcher didUpdateBeaconsScannedInRange:(NSArray *)beacons {
    NSMutableArray *pbBeacons = [NSMutableArray array];
    for (CLBeacon *beacon in beacons) {
        PBBeacon *localBeacon = [[PBBeacon alloc] initWithCLBeacon:beacon];
        [pbBeacons addObject:localBeacon];
    }
    if ([self.delegate respondsToSelector:@selector(applicationFacade: didReceiveScannedBeacons:)]) {
        [self.delegate applicationFacade:self didReceiveScannedBeacons:pbBeacons];
    }
}


- (void)bluetoothDidFailWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(applicationFacade: didFailBluetoothServiceWithError:)]) {
        [self.delegate applicationFacade:self didFailBluetoothServiceWithError:error];
    }
}


#pragma mark - Helper methods


- (void)compareLocalCards:(NSArray *)localCards withWebCards:(NSArray *)webCards result:(void (^)(NSArray *cardsForAdd, NSArray *cardsForDelete, NSArray *cardsForUpdate))result {
    NSMutableArray *arrayForDelete = [NSMutableArray array];
    NSMutableArray *arrayForAdd = nil;
    NSMutableArray *arrayForUpdate = [NSMutableArray array];
    NSMutableArray *equalsObjects = [NSMutableArray array];

    [localCards enumerateObjectsUsingBlock:^(PBCard *localCard, NSUInteger indexLocal, BOOL *stopLocal) {
        __block BOOL isExisting = NO;
        [webCards enumerateObjectsUsingBlock:^(PBCard *webCard, NSUInteger indexWeb, BOOL *stopWeb) {
            if ([localCard isEqual:webCard]) {
                isExisting = YES;
                [equalsObjects addObject:webCard];
                if (localCard.version != webCard.version) {
                    [arrayForUpdate addObject:webCard];
                }
                *stopWeb = YES;
            }
        }];

        if (!isExisting) {
            [arrayForDelete addObject:localCard];
        }
    }];
    arrayForAdd = [webCards mutableCopy];
    [arrayForAdd removeObjectsInArray:equalsObjects];

    if (result) {
        result(arrayForAdd, arrayForDelete, arrayForUpdate);
    }
}


- (void)compareLocalBeacons:(NSArray *)localBeacons withWebBeacons:(NSArray *)webBeacons result:(void (^)(NSArray *beaconsForAdd, NSArray *beaconsForDelete, NSArray *beaconsForUpdate))result {
    NSMutableArray *arrayForDelete = [NSMutableArray array];
    NSMutableArray *arrayForAdd = nil;
    NSMutableArray *arrayForUpdate = [NSMutableArray array];
    NSMutableArray *equalsObjects = [NSMutableArray array];

    [localBeacons enumerateObjectsUsingBlock:^(PBBeacon *localBeacon, NSUInteger indexLocal, BOOL *stopLocal) {
        __block BOOL isExisting = NO;
        [webBeacons enumerateObjectsUsingBlock:^(PBBeacon *webBeacon, NSUInteger indexWeb, BOOL *stopWeb) {
            if ([localBeacon isEqual:webBeacon]) {
                isExisting = YES;
                [equalsObjects addObject:webBeacon];
                if (localBeacon.version != webBeacon.version) {
                    [arrayForUpdate addObject:webBeacon];
                }
                *stopWeb = YES;
            }
        }];

        if (!isExisting) {
            [arrayForDelete addObject:localBeacon];
        }
    }];
    arrayForAdd = [webBeacons mutableCopy];
    [arrayForAdd removeObjectsInArray:equalsObjects];

    if (result) {
        result(arrayForAdd, arrayForDelete, arrayForUpdate);
    }
}


- (void)compareOldBeacons:(NSArray *)oldBeacons withNewBeacons:(NSArray *)newBeacons result:(void (^)(NSArray *beaconsForAdd, NSArray *beaconsForDelete, NSArray *beaconsForUpdate))result {
    NSMutableArray *arrayForDelete = [NSMutableArray array];
    NSMutableArray *arrayForAdd = nil;
    NSMutableArray *arrayForUpdate = [NSMutableArray array];
    NSMutableArray *equalsObjects = [NSMutableArray array];

    [oldBeacons enumerateObjectsUsingBlock:^(PBBeacon *localBeacon, NSUInteger indexLocal, BOOL *stopLocal) {
        __block BOOL isExisting = NO;
        [newBeacons enumerateObjectsUsingBlock:^(PBBeacon *webBeacon, NSUInteger indexWeb, BOOL *stopWeb) {
            if ([localBeacon isEqual:webBeacon]) {
                isExisting = YES;
                [equalsObjects addObject:webBeacon];
                if (localBeacon.state != webBeacon.state) {
                    [arrayForUpdate addObject:webBeacon];
                }
                *stopWeb = YES;
            }
        }];

        if (!isExisting) {
            [arrayForDelete addObject:localBeacon];
        }
    }];
    arrayForAdd = [newBeacons mutableCopy];
    [arrayForAdd removeObjectsInArray:equalsObjects];

    if (result) {
        result(arrayForAdd, arrayForDelete, arrayForUpdate);
    }
}


- (void)compareOldShares:(NSArray *)oldShares withNewShares:(NSArray *)newShares result:(void (^)(NSArray *sharesForAdd, NSArray *sharesForDelete, NSArray *sharesForUpdate))result {
    NSMutableArray *arrayForDelete = [NSMutableArray array];
    NSMutableArray *arrayForAdd = nil;
    NSMutableArray *arrayForUpdate = [NSMutableArray array];
    NSMutableArray *equalsObjects = [NSMutableArray array];

    [oldShares enumerateObjectsUsingBlock:^(PBCardsShare *oldShare, NSUInteger indexLocal, BOOL *stopLocal) {
        __block BOOL isExisting = NO;
        [newShares enumerateObjectsUsingBlock:^(PBCardsShare *newShare, NSUInteger indexWeb, BOOL *stopWeb) {
            if ([oldShare isEqual:newShare]) {
                isExisting = YES;
                [equalsObjects addObject:newShare];
                if (oldShare.permission != newShare.permission) {
                    [arrayForUpdate addObject:newShare];
                }
                *stopWeb = YES;
            }
        }];

        if (!isExisting) {
            [arrayForDelete addObject:oldShare];
        }
    }];
    arrayForAdd = [newShares mutableCopy];
    [arrayForAdd removeObjectsInArray:equalsObjects];

    if (result) {
        result(arrayForAdd, arrayForDelete, arrayForUpdate);
    }
}


- (void)compareOldUids:(NSArray *)oldUids withNewUids:(NSArray *)newUids result:(void (^)(NSArray *beaconsForAdd, NSArray *beaconsForDelete))result {
    __block NSMutableArray *arrayForDelete = [NSMutableArray array];
    __block NSMutableArray *arrayForAdd = nil;

    [oldUids enumerateObjectsUsingBlock:^(NSString *oldUid, NSUInteger indexLocal, BOOL *stopOld) {
        __block BOOL isExisting = NO;
        [newUids enumerateObjectsUsingBlock:^(NSString *newUid, NSUInteger indexWeb, BOOL *stopNew) {
            if ([oldUid isEqualToString:newUid]) {
                isExisting = YES;
                *stopNew = YES;
            }
        }];

        if (!isExisting) {
            [arrayForDelete addObject:oldUid];
        }
    }];
    arrayForAdd = [newUids mutableCopy];

    if (result) {
        result(arrayForAdd, arrayForDelete);
    }
}


- (NSArray *)mapToLocalCards:(NSArray *)webCards {
    NSMutableArray *results = [NSMutableArray array];
    for (PBWebCard *webCard in webCards) {
        PBCard *card = [[PBCard alloc] init];
        [card fromWebModel:webCard];
        [results addObject:card];
    }
    return results;
}

@end