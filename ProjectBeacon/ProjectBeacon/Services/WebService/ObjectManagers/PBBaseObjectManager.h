//
// Created by Oleksandr Malyarenko on 12/9/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>


static NSString *const kAuthorizationParamsNotification = @"AuthorizationParamsNotification";
static NSString *const kAuthProviderName = @"AuthProviderName";
static NSString *const kAuthKey = @"AuthKey";


@interface PBBaseObjectManager : RKObjectManager


@property (nonatomic, strong) NSString *authProviderName;
@property (nonatomic, strong) NSString *authKey;

- (void)setupResponseDescriptors;

- (void)setupRequestDescriptors;

@end