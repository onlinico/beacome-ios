//
// Created by Oleksandr Malyarenko on 12/1/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "PBBaseModel.h"


@interface PBBeacon : PBBaseModel


@property (nonatomic, strong) NSString *beaconUid;
@property (nonatomic, assign) NSInteger major;
@property (nonatomic, assign) NSInteger minor;
@property (nonatomic, assign) NSInteger power;
@property (nonatomic, assign) BOOL state;
@property (nonatomic, assign) NSInteger version;
@property (nonatomic, assign) NSInteger linkedCardsCount;
@property (nonatomic, strong) NSArray *cards;

- (instancetype)initWithCLBeacon:(CLBeacon *)beacon;
@end