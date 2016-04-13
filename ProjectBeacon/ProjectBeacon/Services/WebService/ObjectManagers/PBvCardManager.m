//
// Created by Oleksandr Malyarenko on 12/9/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBvCardManager.h"
#import "PBWebVCard.h"


@implementation PBvCardManager {

}


- (void)getVCardById:(NSInteger)guid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:[NSString stringWithFormat:@"VCards/%li", (long) guid] parameters:nil success:success failure:failure];
}


- (void)postVCard:(PBWebVCard *)vCard success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self postObject:vCard path:@"VCards" parameters:nil success:success failure:failure];
}


- (void)putVCard:(PBWebVCard *)vCard success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self putObject:vCard path:[NSString stringWithFormat:@"VCards/%@", @(vCard.id)] parameters:nil success:success failure:failure];
}


- (void)deleteVCard:(PBWebVCard *)vCard success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self deleteObject:vCard path:[NSString stringWithFormat:@"VCards/%@", @(vCard.id)] parameters:nil success:success failure:failure];
}


#pragma mark - Helper methods


- (void)setupResponseDescriptors {
    [super setupResponseDescriptors];

    RKResponseDescriptor *beaconResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebVCard mapping] method:RKRequestMethodGET pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    [self addResponseDescriptorsFromArray:@[beaconResponseDescriptor]];

}


- (void)setupRequestDescriptors {
    [super setupRequestDescriptors];

    RKRequestDescriptor *beaconRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[RKObjectMapping requestMapping] objectClass:[PBWebVCard class] rootKeyPath:nil method:RKRequestMethodAny];

    [self addRequestDescriptorsFromArray:@[beaconRequestDescriptor]];
}

@end