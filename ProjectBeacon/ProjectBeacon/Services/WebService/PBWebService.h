//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import "Models.h"


@class PBWebCard;
@class PBWebBeacon;
@class PBWebVCard;
@class PBWebUser;
@class PBWebUserSocial;
@class PBWebUserSocialLinks;
@class PBWebCardsShare;


@interface PBWebService : NSObject


- (void)setupAuthProvider:(NSString *)authProvider authKey:(NSString *)authKey;

- (void)signInWithAccessToken:(NSString *)accessToken success:(void (^)(PBWebUser *webUser))success failure:(void (^)(NSError *error))failure;

- (void)signOutWithSuccess:(void (^)(BOOL success))success failure:(void (^)(NSError *error))failure;

// Cards methods

- (void)loadHistoryWithSuccess:(void (^)(NSArray *cards))success failure:(void (^)(NSError *error))failure;

- (void)getUserCardsWithSuccess:(void (^)(NSArray *cards))success failure:(void (^)(NSError *error))failure;

- (void)getCardByGuid:(NSString *)guid success:(void (^)(PBWebCard *card))success failure:(void (^)(NSError *error))failure;

- (void)getCardsByBeaconGuid:(NSString *)guid success:(void (^)(NSArray *cards))success failure:(void (^)(NSError *error))failure;

- (void)getDetailForCardGuid:(NSString *)guid success:(void (^)(PBWebCard *detailCard))success failure:(void (^)(NSError *error))failure;

- (void)getImageForCardGuid:(NSString *)guid success:(void (^)(NSData *imageData))success failure:(void (^)(NSError *error))failure;

- (void)acceptCardSharing:(NSString *)shareGuid success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure;

- (void)insertCard:(PBWebCard *)card success:(void (^)(PBWebCard *addedCard))success failure:(void (^)(NSError *error))failure;

- (void)updateCard:(PBWebCard *)card success:(void (^)(PBWebCard *updatedCard))success failure:(void (^)(NSError *error))failure;

- (void)deleteCard:(PBWebCard *)card success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure;

- (void)shareCard:(PBWebCard *)card toUserByEmail:(NSString *)email withPermission:(BOOL)permission success:(void (^)(BOOL status, PBWebCardsShare *webCardsShare))success failure:(void (^)(NSError *error))failure;

- (void)changePermission:(BOOL)permission forShareGuid:(NSString *)shareGuid success:(void (^)(BOOL status, PBWebCardsShare *webCardsShare))success failure:(void (^)(NSError *error))failure;

- (void)deleteSharingForGuid:(NSString *)shareGuid success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure;

- (void)changePermission:(BOOL)permission forUserId:(NSInteger)userId cardGuid:(NSString *)cardGuid success:(void (^)(BOOL status, PBWebCardsShare *webCardsShare))success failure:(void (^)(NSError *error))failure;

- (void)deleteSharingForUserId:(NSInteger)userId cardGuid:(NSString *)cardGuid success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure;

- (void)setFavourite:(BOOL)favourite forCard:(PBWebCard *)card success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure;

// Beacons methods

- (void)getAllUserBeaconsWithSuccess:(void (^)(NSArray *beacons))success failure:(void (^)(NSError *error))failure;

- (void)getBeaconsForCardGuid:(NSString *)guid success:(void (^)(NSArray *beacons))success failure:(void (^)(NSError *error))failure;

- (void)getDetailsForBeaconGuid:(NSString *)guid success:(void (^)(PBWebBeacon *beacon))success failure:(void (^)(NSError *error))failure;

- (void)insertBeacon:(PBWebBeacon *)beacon success:(void (^)(PBWebBeacon *insertedBeacon))success failure:(void (^)(NSError *error))failure;

- (void)updateBeacon:(PBWebBeacon *)beacon success:(void (^)(PBWebBeacon *updatedBeacon))success failure:(void (^)(NSError *error))failure;

- (void)deleteBeacon:(PBWebBeacon *)beacon success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure;

// vCards methods



- (void)getVCardById:(NSInteger)id success:(void (^)(PBWebVCard *vCard))success failure:(void (^)(NSError *error))failure;

- (void)insertVCard:(PBWebVCard *)vCard success:(void (^)(NSInteger vCardId))success failure:(void (^)(NSError *error))failure;

- (void)updateVCard:(PBWebVCard *)vCard success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure;

- (void)deleteVCard:(PBWebVCard *)vCard success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure;

// Users methods

- (void)getUserById:(NSInteger)id success:(void (^)(PBWebUser *webUser))success failure:(void (^)(NSError *error))failure;

- (void)insertUser:(PBWebUser *)user success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure;

- (void)updatetUser:(PBWebUser *)user success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure;

- (void)getSocial:(PBWebUser *)user success:(void (^)(PBWebUserSocial *userSocial))success failure:(void (^)(NSError *error))failure;

- (void)linkSocial:(PBWebUserSocialLinks *)socialLinks success:(void (^)(PBWebUserSocial *social))success failure:(void (^)(NSError *error))failure;

@end