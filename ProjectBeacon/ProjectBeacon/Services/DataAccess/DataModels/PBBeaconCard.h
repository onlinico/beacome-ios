//
// Created by Oleksandr Malyarenko on 1/8/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseModel.h"


@interface PBBeaconCard : PBBaseModel


@property (nonatomic, strong) NSString *cardGuid;
@property (nonatomic, assign) BOOL isActive;

@end