//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>


@class PBBaseModel;


@interface PBWebBaseModel : NSObject


+ (RKMapping *)mapping;

+ (RKMapping *)requestMapping;

- (void)fromLocalModel:(PBBaseModel *)model;

@end