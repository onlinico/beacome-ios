//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWebBaseModel.h"


@interface PBWebContact : PBWebBaseModel


@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) NSInteger contactType;
@property (nonatomic, strong) NSString *data;

@end