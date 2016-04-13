//
// Created by Oleksandr Malyarenko on 12/21/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseModel.h"


@interface PBCardsShare : PBBaseModel


@property (nonatomic, assign) NSInteger id;
@property (nonatomic, strong) NSString *shareGuid;
@property (nonatomic, strong) NSString *cardId;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, assign) BOOL permission;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, assign) NSInteger version;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSData *photo;

@end