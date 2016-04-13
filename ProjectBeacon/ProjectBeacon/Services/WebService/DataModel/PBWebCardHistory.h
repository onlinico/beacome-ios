//
// Created by Oleksandr Malyarenko on 2/3/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWebBaseModel.h"


@interface PBWebCardHistory : PBWebBaseModel


@property (nonatomic, strong) NSString *cardGuid;
@property (nonatomic, assign) NSTimeInterval received;
@property (nonatomic, assign) BOOL isFavorite;

@end