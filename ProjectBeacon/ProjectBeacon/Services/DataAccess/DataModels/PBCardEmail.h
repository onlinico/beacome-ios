//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseModel.h"


typedef NS_ENUM(NSInteger, PBEmailType) {
    PBEmailTypePersonal = 201,
    PBEmailTypeWork,
    PBEmailTypeOther
};


@interface PBCardEmail : PBBaseModel


@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) PBEmailType emailType;
@property (nonatomic, strong) NSString *email;
@end