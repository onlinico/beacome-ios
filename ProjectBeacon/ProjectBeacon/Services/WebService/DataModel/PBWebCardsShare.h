//
// Created by Oleksandr Malyarenko on 12/21/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWebBaseModel.h"


@interface PBWebCardsShare : PBWebBaseModel


@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) BOOL isOwner;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *shareGuid;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *photo;

@end