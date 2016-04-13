//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBWebService.h"
#import "PBBaseObjectManager.h"
#import "PBBeaconManager.h"
#import "PBCardManager.h"
#import "PBUserManager.h"
#import "PBvCardManager.h"
#import "PBWebCard.h"
#import "PBWebBeacon.h"
#import "PBWebVCard.h"
#import "PBWebUser.h"
#import "PBWebUserSocial.h"
#import "PBWebUserSocialLinks.h"
#import "PBWebCardsShare.h"
#import "PBShareManager.h"


static NSString *const kTestApiBaseUrl = @"http://dev3.onlini.co:8080/api/";
static NSString *const kApiBaseUrl = @"https://www.beaco.me/api/";

@interface PBWebService ()


@property (nonatomic, strong) PBBeaconManager *beaconManager;
@property (nonatomic, strong) PBCardManager *cardManager;
@property (nonatomic, strong) PBUserManager *userManager;
@property (nonatomic, strong) PBvCardManager *vCardManager;
@property (nonatomic, strong) PBShareManager *shareManager;

@end


@implementation PBWebService {

}


- (instancetype)init {
    if (self = [super init]) {
        // initialize AFNetworking HTTPClient
#if DEBUG
        NSURL *baseURL = [NSURL URLWithString:kTestApiBaseUrl];
#else
        NSURL *baseURL = [NSURL URLWithString:kApiBaseUrl];
#endif
        AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
        client.allowsInvalidSSLCertificate = YES;

        // initialize RestKit
        self.beaconManager = [[PBBeaconManager alloc] initWithHTTPClient:client];
        self.cardManager = [[PBCardManager alloc] initWithHTTPClient:client];
        self.vCardManager = [[PBvCardManager alloc] initWithHTTPClient:client];
        self.userManager = [[PBUserManager alloc] initWithHTTPClient:client];
        self.shareManager = [[PBShareManager alloc] initWithHTTPClient:client];
    }

    return self;
}


#pragma mark - Main methods


- (void)setupAuthProvider:(nonnull NSString *)authProvider authKey:(nonnull NSString *)authKey {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAuthorizationParamsNotification object:@{kAuthProviderName : authProvider ? authProvider : [NSNull null], kAuthKey : authKey ? authKey : [NSNull null]}];
}


- (void)signInWithAccessToken:(NSString *)accessToken success:(void (^)(PBWebUser *webUser))success failure:(void (^)(NSError *error))failure {
    [self.userManager getUserByAccessToken:accessToken success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.firstObject);
        }
    }                              failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)signOutWithSuccess:(void (^)(BOOL success))success failure:(void (^)(NSError *error))failure {
    [self.userManager signOutWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)loadHistoryWithSuccess:(void (^)(NSArray *cards))success failure:(void (^)(NSError *error))failure {
    [self.cardManager loadHistoryWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.array);
        }
    }                                failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)getUserCardsWithSuccess:(void (^)(NSArray *cards))success failure:(void (^)(NSError *error))failure {
    [self.cardManager getUserCardsWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.array);
        }
    }                                 failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)getCardByGuid:(NSString *)guid success:(void (^)(PBWebCard *card))success failure:(void (^)(NSError *error))failure {
    [self.cardManager getCardByGuid:guid success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.firstObject);
        }
    }                       failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)getCardsByBeaconGuid:(NSString *)guid success:(void (^)(NSArray *cards))success failure:(void (^)(NSError *error))failure {
    [self.cardManager getCardsByBeaconGuid:guid success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.array);
        }
    }                              failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)getDetailForCardGuid:(NSString *)guid success:(void (^)(PBWebCard *detailCard))success failure:(void (^)(NSError *error))failure {
    [self.cardManager getCardDetailByGuid:guid success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.firstObject);
        }
    }                             failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)getImageForCardGuid:(NSString *)guid success:(void (^)(NSData *imageData))success failure:(void (^)(NSError *error))failure {
    [self.cardManager getImageForCardGuid:guid success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
        NSData *data = nil;
        if (requestOperation.responseString && requestOperation.responseString.length > 0) {
            data = [[NSData alloc] initWithBase64EncodedString:requestOperation.responseString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        }
        if (success) {
            success(data);
        }
    }                             failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)acceptCardSharing:(NSString *)shareGuid success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.shareManager acceptShare:shareGuid success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                    failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)insertCard:(PBWebCard *)card success:(void (^)(PBWebCard *addedCard))success failure:(void (^)(NSError *error))failure {
    [self.cardManager postCard:card success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        PBWebCard *webCard = mappingResult.firstObject;
        if (success) {
            success(webCard);
        }

    }                  failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)updateCard:(PBWebCard *)card success:(void (^)(PBWebCard *updatedCard))success failure:(void (^)(NSError *error))failure {
    [self.cardManager putCard:card success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        PBWebCard *webCard = mappingResult.firstObject;
        if (success) {
            success(webCard);
        }
    }                 failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)deleteCard:(PBWebCard *)card success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.cardManager deleteCard:card success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                    failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)shareCard:(PBWebCard *)card toUserByEmail:(NSString *)email withPermission:(BOOL)permission success:(void (^)(BOOL status, PBWebCardsShare *webCardsShare))success failure:(void (^)(NSError *error))failure {
    [self.shareManager shareCard:card toUserEmail:email withPermission:permission success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES, mappingResult.firstObject);
        }
    }                    failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)changePermission:(BOOL)permission forShareGuid:(NSString *)shareGuid success:(void (^)(BOOL status, PBWebCardsShare *webCardsShare))success failure:(void (^)(NSError *error))failure {
    [self.shareManager changeSharingPermission:permission forShareGuid:shareGuid success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES, mappingResult.firstObject);
        }
    }                                  failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)deleteSharingForGuid:(NSString *)shareGuid success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.shareManager deleteSharingForShareGuid:shareGuid success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                                    failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

}


- (void)changePermission:(BOOL)permission forUserId:(NSInteger)userId cardGuid:(NSString *)cardGuid success:(void (^)(BOOL status, PBWebCardsShare *webCardsShare))success failure:(void (^)(NSError *error))failure {
    [self.shareManager changeSharingPermission:permission forUserId:userId cardGuid:cardGuid success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES, mappingResult.firstObject);
        }
    }                                  failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)deleteSharingForUserId:(NSInteger)userId cardGuid:(NSString *)cardGuid success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.shareManager deleteSharingForUserId:userId cardGuid:cardGuid success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                                 failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)linkBeacons:(NSArray *)beaconsGuids toCardGuid:(NSString *)cardId success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.cardManager linkBeacons:beaconsGuids toCardGuid:cardId success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                     failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)unlinkBeacons:(NSArray *)beaconsGuids fromCardGuid:(NSString *)cardId success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.cardManager unlinkBeacons:beaconsGuids fromCardGuid:cardId success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                       failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)setFavourite:(BOOL)favourite forCard:(PBWebCard *)card success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.cardManager setFavourite:favourite forCard:card success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)getAllUserBeaconsWithSuccess:(void (^)(NSArray *beacons))success failure:(void (^)(NSError *error))failure {
    [self.beaconManager getBeaconsWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.array);
        }
    }                                 failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

}


- (void)getBeaconsForCardGuid:(NSString *)guid success:(void (^)(NSArray *beacons))success failure:(void (^)(NSError *error))failure {
    [self.beaconManager getBeaconsByCardGuid:guid success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.array);
        }
    }                                failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

}


- (void)getDetailsForBeaconGuid:(NSString *)guid success:(void (^)(PBWebBeacon *beacon))success failure:(void (^)(NSError *error))failure {
    [self.beaconManager getBeaconByGuid:guid success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.firstObject);
        }
    }                           failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)insertBeacon:(PBWebBeacon *)beacon success:(void (^)(PBWebBeacon *insertedBeacon))success failure:(void (^)(NSError *error))failure {
    [self.beaconManager postBeacon:beacon success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        PBWebBeacon *webBeacon = mappingResult.firstObject;
        if (success) {
            success(webBeacon);
        }
    }                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)updateBeacon:(PBWebBeacon *)beacon success:(void (^)(PBWebBeacon *updatedBeacon))success failure:(void (^)(NSError *error))failure {
    [self.beaconManager putBeacon:beacon success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        PBWebBeacon *webBeacon = mappingResult.firstObject;
        if (success) {
            success(webBeacon);
        }
    }                     failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)deleteBeacon:(PBWebBeacon *)beacon success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.beaconManager deleteBeacon:beacon success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                        failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)getVCardById:(NSInteger)id success:(void (^)(PBWebVCard *vCard))success failure:(void (^)(NSError *error))failure {
    [self.vCardManager getVCardById:id success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.firstObject);
        }
    }                       failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)insertVCard:(PBWebVCard *)vCard success:(void (^)(NSInteger vCardId))success failure:(void (^)(NSError *error))failure {
    [self.vCardManager postVCard:vCard success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        PBWebVCard *webVCard = mappingResult.firstObject;
        if (success) {
            success(webVCard.id);
        }
    }                    failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)updateVCard:(PBWebVCard *)vCard success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.vCardManager putVCard:vCard success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                   failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)deleteVCard:(PBWebVCard *)vCard success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.vCardManager deleteVCard:vCard success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)getUserById:(NSInteger)id success:(void (^)(PBWebUser *webUser))success failure:(void (^)(NSError *error))failure {
    [self.userManager getUserById:id success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.firstObject);
        }
    }                     failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)insertUser:(PBWebUser *)user success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.userManager postUser:user success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                  failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)updatetUser:(PBWebUser *)user success:(void (^)(BOOL status))success failure:(void (^)(NSError *error))failure {
    [self.userManager putUser:user success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(YES);
        }
    }                 failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)getSocial:(PBWebUser *)user success:(void (^)(PBWebUserSocial *userSocial))success failure:(void (^)(NSError *error))failure; {
    [self.userManager getSocial:user success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.firstObject);
        }
    }                   failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void)linkSocial:(PBWebUserSocialLinks *)socialLinks success:(void (^)(PBWebUserSocial *social))success failure:(void (^)(NSError *error))failure {
    [self.userManager linkSocial:socialLinks success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (success) {
            success(mappingResult.firstObject);
        }
    }                    failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

@end