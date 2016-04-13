//
// Created by Oleksandr Malyarenko on 1/11/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWebBaseModel.h"


@interface PBWebUserSocial : PBWebBaseModel


@property (nonatomic, assign) BOOL facebook;
@property (nonatomic, assign) BOOL twitter;
@property (nonatomic, assign) BOOL google;

@end