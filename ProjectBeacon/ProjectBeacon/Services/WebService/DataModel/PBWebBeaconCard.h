//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWebBaseModel.h"


@interface PBWebBeaconCard : PBWebBaseModel


@property (nonatomic, strong) NSString *cardGuid;
@property (nonatomic, assign) BOOL isActive;

@end