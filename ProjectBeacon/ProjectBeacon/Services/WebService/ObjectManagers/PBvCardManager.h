//
// Created by Oleksandr Malyarenko on 12/9/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseObjectManager.h"


@class PBWebVCard;


@interface PBvCardManager : PBBaseObjectManager


- (void)getVCardById:(NSInteger)id success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)postVCard:(PBWebVCard *)vCard success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)putVCard:(PBWebVCard *)vCard success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)deleteVCard:(PBWebVCard *)vCard success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

@end