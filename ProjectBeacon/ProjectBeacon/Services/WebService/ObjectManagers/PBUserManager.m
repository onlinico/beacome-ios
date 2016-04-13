//
// Created by Oleksandr Malyarenko on 12/9/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBUserManager.h"
#import "PBWebUser.h"
#import "PBWebUserSocial.h"
#import "PBWebUserSocialLinks.h"


@implementation PBUserManager {

}


#pragma mark - Helper methods


- (void)setupResponseDescriptors {
    RKResponseDescriptor *authenticatedUserResponseDescriptors = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebUser mapping] method:RKRequestMethodGET pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *putResponseDescriptors = [RKResponseDescriptor responseDescriptorWithMapping:[RKObjectMapping mappingForClass:[NSObject class]] method:RKRequestMethodPUT pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *logoutResponseDescriptors = [RKResponseDescriptor responseDescriptorWithMapping:[RKObjectMapping mappingForClass:[NSObject class]] method:RKRequestMethodGET pathPattern:@"Users/Logout" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *getSocialResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebUserSocial mapping] method:RKRequestMethodGET pathPattern:@"Users/SocialLinks" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *putSocialResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[PBWebUserSocial mapping] method:RKRequestMethodPUT pathPattern:@"Users/SocialLinks" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    [self addResponseDescriptorsFromArray:@[authenticatedUserResponseDescriptors, getSocialResponseDescriptor, putResponseDescriptors, putSocialResponseDescriptor, logoutResponseDescriptors]];
}


- (void)setupRequestDescriptors {
    RKRequestDescriptor *putRequest = [RKRequestDescriptor requestDescriptorWithMapping:[PBWebUser requestMapping] objectClass:[PBWebUser class] rootKeyPath:nil method:RKRequestMethodPUT];
    RKRequestDescriptor *putSocialsRequest = [RKRequestDescriptor requestDescriptorWithMapping:[PBWebUserSocialLinks requestMapping] objectClass:[PBWebUserSocialLinks class] rootKeyPath:nil method:RKRequestMethodPUT];
    [self addRequestDescriptorsFromArray:@[putRequest, putSocialsRequest]];
    [self.router.routeSet addRoute:[RKRoute routeWithClass:[PBWebUser class] pathPattern:@"Users" method:RKRequestMethodPUT]];
}


- (void)getUserByAccessToken:(NSString *)token success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:@"Users/ByAccessToken" parameters:nil success:success failure:failure];
}


- (void)getUserById:(NSInteger)id success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:[NSString stringWithFormat:@"Users/%ld", (long) id] parameters:nil success:success failure:failure];

}


- (void)postUser:(PBWebUser *)user success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self postObject:user path:@"Users" parameters:nil success:success failure:failure];
}


- (void)putUser:(PBWebUser *)user success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self putObject:user path:nil parameters:nil success:success failure:failure];
}


- (void)getSocial:(PBWebUser *)user success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:@"Users/SocialLinks" parameters:nil success:success failure:failure];
}


- (void)linkSocial:(PBWebUserSocialLinks *)social success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self putObject:social path:@"Users/SocialLinks" parameters:nil success:success failure:failure];
}


- (void)signOutWithSuccess:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure {
    [self getObjectsAtPath:@"Users/Logout" parameters:nil success:success failure:failure];
}

@end