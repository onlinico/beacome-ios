//
// Created by Oleksandr Malyarenko on 2/1/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWebBaseModel.h"


@interface PBWebUserSocialLinks : PBWebBaseModel


@property (nonatomic, strong) NSString *facebook;
@property (nonatomic, strong) NSString *twitter;
@property (nonatomic, strong) NSString *google;

@end