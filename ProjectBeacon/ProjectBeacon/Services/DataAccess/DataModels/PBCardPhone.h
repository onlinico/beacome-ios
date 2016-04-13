//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseModel.h"


typedef NS_ENUM(NSInteger, PBPhoneType) {
    PBPhoneTypeMobile = 101,
    PBPhoneTypeHome,
    PBPhoneTypeWork,
    PBPhoneTypeCompany,
    PBPhoneTypeFax,
    PBPhoneTypeOther
};


@interface PBCardPhone : PBBaseModel


@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) PBPhoneType phoneType;
@property (nonatomic, strong) NSString *phoneNumber;

@end