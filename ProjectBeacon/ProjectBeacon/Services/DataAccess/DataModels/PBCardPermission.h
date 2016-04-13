//
// Created by Oleksandr Malyarenko on 11/30/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+GUID.h"
#import "PBBaseModel.h"


@interface PBCardPermission : PBBaseModel


@property (nonatomic, strong) GUID *id;
@property (nonatomic, strong) GUID *userId;
@property (nonatomic, strong) NSNumber *cardId;
@property (nonatomic, assign) NSUInteger permission;

@end