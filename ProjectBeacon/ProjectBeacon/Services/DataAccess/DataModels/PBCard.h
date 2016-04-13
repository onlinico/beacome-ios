//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CardModel.h"
#import "PBBaseModel.h"


@class PBCardHistory;

typedef NS_ENUM(NSUInteger, PBCardPermission) {
    PBCardPermissionTranslator,
    PBCardPermissionOwner
};


@interface PBCard : PBBaseModel


@property (nonatomic, strong) NSString *cardId;
@property (nonatomic, assign) PBCardPermission permission;
@property (nonatomic, strong) NSData *logo;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSArray *phones;
@property (nonatomic, strong) NSArray *emails;
@property (nonatomic, strong) NSArray *urls;
@property (nonatomic, strong) NSArray *vCards;
@property (nonatomic, strong) NSArray *beacons;
@property (nonatomic, assign) NSInteger beaconsCount;
@property (nonatomic, assign) NSInteger version;
@property (nonatomic, assign) BOOL shortInfo;
@property (nonatomic, strong) NSArray *cardShare;

//history
@property (nonatomic, strong) NSDate *visitDate;
@property (nonatomic, assign) BOOL isFavourite;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double distance;

- (void)setupCardHistory:(PBCardHistory *)cardHistory;

@end