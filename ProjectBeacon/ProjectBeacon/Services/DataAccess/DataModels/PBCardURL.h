//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseModel.h"


typedef NS_ENUM(NSInteger, PBUrlType) {
    PBUrlWebsite = 301,
    PBUrlSkype
};


@interface PBCardURL : PBBaseModel


@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) PBUrlType urlType;
@property (nonatomic, strong) NSString *url;

@end