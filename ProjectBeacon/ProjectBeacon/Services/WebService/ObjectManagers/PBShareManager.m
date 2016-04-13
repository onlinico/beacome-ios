//
// Created by Oleksandr Malyarenko on 2/4/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import "PBShareManager.h"
#import "PBWebCardsShare.h"
#import "PBWebCard.h"
#import "NSString+BOOL.h"


@implementation PBShareManager {

}


- (void)acceptShare:(NSString *)shareGuid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self putObject:nil path:[NSString stringWithFormat:@"Cards/Share/Accept/%@", shareGuid] parameters:nil success:success failure:failure];
}


- (void)shareCard:(PBWebCard *)card toUserEmail:(NSString *)userEmail withPermission:(BOOL)permission success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self postObject:nil path:[NSString stringWithFormat:@"Cards/Share/%@/%@/%@", card.guid, [NSString stringFromBool:permission], userEmail] parameters:nil success:success failure:failure];
}


- (void)changeSharingPermission:(BOOL)permission forShareGuid:(NSString *)shareGuid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self putObject:nil path:[NSString stringWithFormat:@"Cards/Share/%@/%@", shareGuid, [NSString stringFromBool:permission]] parameters:nil success:success failure:failure];
}


- (void)deleteSharingForShareGuid:(NSString *)shareGuid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self deleteObject:nil path:[NSString stringWithFormat:@"Cards/Share/%@", shareGuid] parameters:nil success:success failure:failure];
}


- (void)changeSharingPermission:(BOOL)permission forUserId:(NSInteger)userId cardGuid:(NSString *)cardGuid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self putObject:nil path:[NSString stringWithFormat:@"Cards/UserCard/%ld/%@/%@", (long) userId, cardGuid, [NSString stringFromBool:permission]] parameters:nil success:success failure:failure];
}


- (void)deleteSharingForUserId:(NSInteger)userId cardGuid:(NSString *)cardGuid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self deleteObject:nil path:[NSString stringWithFormat:@"Cards/UserCard/%ld/%@", (long) userId, cardGuid] parameters:nil success:success failure:failure];
}


#pragma mark - Helper methods


- (void)setupResponseDescriptors {
    [super setupResponseDescriptors];
    RKResponseDescriptor *emptyResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[RKObjectMapping mappingForClass:[NSObject class]] method:RKRequestMethodAny pathPattern:@"Cards/Share" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *cardShareResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebCardsShare mapping] method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    [self addResponseDescriptorsFromArray:@[emptyResponseDescriptor, cardShareResponseDescriptor]];

}


- (void)setupRequestDescriptors {
    [super setupRequestDescriptors];

}

@end