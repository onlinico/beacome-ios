//
// Created by Oleksandr Malyarenko on 12/1/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseModel.h"


@interface PBCardHistory : PBBaseModel


@property (nonatomic, strong) NSString *cardId;
@property (nonatomic, strong) NSDate *visitDate;
@property (nonatomic, assign) BOOL isFavourite;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double distance;

@end