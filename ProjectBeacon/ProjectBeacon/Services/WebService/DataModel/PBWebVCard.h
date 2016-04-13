//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWebBaseModel.h"


@interface PBWebVCard : PBWebBaseModel


@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) NSInteger timestamp;
@property (nonatomic, strong) NSString *photo;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *vCardData;

@end