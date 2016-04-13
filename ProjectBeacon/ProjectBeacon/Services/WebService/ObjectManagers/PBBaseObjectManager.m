//
// Created by Oleksandr Malyarenko on 12/9/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBBaseObjectManager.h"


@implementation PBBaseObjectManager {

}


- (instancetype)initWithHTTPClient:(AFHTTPClient *)client {
    if (self = [super initWithHTTPClient:client]) {

        [self setupResponseDescriptors];
        [self setupRequestDescriptors];
        self.requestSerializationMIMEType = RKMIMETypeJSON;

        [self setAcceptHeaderWithMIMEType:RKMIMETypeJSON];
        [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"text/plain"];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAuthorizationParams:) name:kAuthorizationParamsNotification object:nil];
    }

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setAuthorizationParams:(NSNotification *)notification {
    if (notification.object) {
        self.authProviderName = notification.object[kAuthProviderName];
        self.authKey = notification.object[kAuthKey];
        if (![self.authProviderName isMemberOfClass:[NSNull class]]) {
            [self.HTTPClient setDefaultHeader:@"authProviderName" value:self.authProviderName];
        }
        if (![self.authKey isMemberOfClass:[NSNull class]]) {
            [self.HTTPClient setDefaultHeader:@"authKey" value:self.authKey];
        }

    }
}


- (void)setupResponseDescriptors {
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
// The entire value at the source key path containing the errors maps to the message
    [errorMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError);
// Any response in the 4xx status code range with an "errors" key path uses this mapping
    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"errors" statusCodes:statusCodes];
    [self addResponseDescriptor:errorDescriptor];
}


- (void)setupRequestDescriptors {
}

@end