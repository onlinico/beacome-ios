//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWebBaseModel.h"


@interface PBWebBeacon : PBWebBaseModel


@property (nonatomic, strong) NSString *uid;
@property (nonatomic, assign) NSInteger major;
@property (nonatomic, assign) NSInteger minor;
@property (nonatomic, assign) NSInteger powerLevel;
@property (nonatomic, assign) NSInteger timestamp;
@property (nonatomic, strong) NSArray *cards;

@end