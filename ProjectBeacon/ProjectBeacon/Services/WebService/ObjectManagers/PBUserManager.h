//
// Created by Oleksandr Malyarenko on 12/9/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseObjectManager.h"


@class PBWebUser;
@class PBWebUserSocialLinks;


@interface PBUserManager : PBBaseObjectManager


- (void)getUserByAccessToken:(NSString *)token success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)getUserById:(NSInteger)id success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)postUser:(PBWebUser *)user success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)putUser:(PBWebUser *)user success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)getSocial:(PBWebUser *)user success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)linkSocial:(PBWebUserSocialLinks *)social success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)signOutWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;
@end