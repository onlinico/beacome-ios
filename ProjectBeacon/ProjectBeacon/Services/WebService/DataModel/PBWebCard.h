//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWebBaseModel.h"


@interface PBWebCard : PBWebBaseModel


@property (nonatomic, strong) NSString *guid;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *logo;
@property (nonatomic, assign) NSInteger timestamp;
@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSArray *vCards;
@property (nonatomic, assign) NSInteger beaconsCount;
@property (nonatomic, strong) NSArray *users;

@end