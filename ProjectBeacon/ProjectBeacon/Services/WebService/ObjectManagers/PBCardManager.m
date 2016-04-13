//
// Created by Oleksandr Malyarenko on 12/9/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBCardManager.h"
#import "PBWebCard.h"
#import "NSString+BOOL.h"
#import "PBWebCardHistory.h"


@implementation PBCardManager {

}


#pragma mark - Methods for work with service


- (void)loadHistoryWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:[NSString stringWithFormat:@"Cards/History"] parameters:nil success:success failure:failure];
}


- (void)getImageForCardGuid:(NSString *)guid success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@Cards/Photo/%@", self.baseURL, guid]]];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:downloadRequest];

    [requestOperation setCompletionBlockWithSuccess:success failure:failure];
    [self.HTTPClient enqueueHTTPRequestOperation:requestOperation];
}


- (void)getUserCardsWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:@"Cards" parameters:nil success:success failure:failure];
}


- (void)getCardByGuid:(NSString *)guid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:[NSString stringWithFormat:@"Cards/%@", guid] parameters:nil success:success failure:failure];
}


- (void)getCardDetailByGuid:(NSString *)guid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:[NSString stringWithFormat:@"Cards/Detail/%@", guid] parameters:nil success:success failure:failure];
}


- (void)getCardsByBeaconGuid:(NSString *)guid success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:[NSString stringWithFormat:@"Cards/Beacon/%@", guid] parameters:nil success:success failure:failure];
}


- (void)postCard:(PBWebCard *)card success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self postObject:card path:@"Cards" parameters:nil success:success failure:failure];
}


- (void)putCard:(PBWebCard *)card success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self putObject:card path:[NSString stringWithFormat:@"Cards/%@", card.guid] parameters:nil success:success failure:failure];
}


- (void)deleteCard:(PBWebCard *)card success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self deleteObject:nil path:[NSString stringWithFormat:@"Cards/%@", card.guid] parameters:nil success:success failure:failure];
}


- (void)setFavourite:(BOOL)isFavourite forCard:(PBWebCard *)card success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self putObject:nil path:[NSString stringWithFormat:@"Cards/Favorite/%@/%@", card.guid, [NSString stringFromBool:isFavourite]] parameters:nil success:success failure:failure];
}


- (void)linkBeacons:(NSArray *)beacons toCardGuid:(NSString *)cardId success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self postObject:beacons path:[NSString stringWithFormat:@"Cards/LinkBeacons/%@", cardId] parameters:nil success:success failure:failure];
}


- (void)unlinkBeacons:(NSArray *)beacons fromCardGuid:(NSString *)cardId success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self deleteObject:beacons path:[NSString stringWithFormat:@"Cards/UnlinkBeacons/%@", cardId] parameters:nil success:success failure:failure];
}


#pragma mark - Helper methods


- (void)setupResponseDescriptors {
    [super setupResponseDescriptors];
    RKResponseDescriptor *emptyResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[RKObjectMapping mappingForClass:[NSObject class]] method:RKRequestMethodAny pathPattern:@"Cards/LinkBeacons" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *stringResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[RKObjectMapping mappingForClass:[NSObject class]] method:RKRequestMethodAny pathPattern:@"Cards/Share" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *userCardsResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebCard mapping] method:RKRequestMethodGET pathPattern:@"Cards" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *userCardResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebCard mapping] method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *cardHistoryResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebCardHistory mapping] method:RKRequestMethodGET pathPattern:@"Cards/History" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    [self addResponseDescriptorsFromArray:@[userCardsResponseDescriptor, userCardResponseDescriptor, stringResponseDescriptor, emptyResponseDescriptor, cardHistoryResponseDescriptor]];

}


- (void)setupRequestDescriptors {
    [super setupRequestDescriptors];

    RKRequestDescriptor *cardRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[PBWebCard requestMapping] objectClass:[PBWebCard class] rootKeyPath:nil method:RKRequestMethodGET];
    RKRequestDescriptor *cardPostRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[PBWebCard requestMapping] objectClass:[PBWebCard class] rootKeyPath:nil method:RKRequestMethodPOST];
    RKRequestDescriptor *cardPutRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[PBWebCard requestMapping] objectClass:[PBWebCard class] rootKeyPath:nil method:RKRequestMethodPUT];

    [self addRequestDescriptorsFromArray:@[cardRequestDescriptor, cardPostRequestDescriptor, cardPutRequestDescriptor]];

}

@end