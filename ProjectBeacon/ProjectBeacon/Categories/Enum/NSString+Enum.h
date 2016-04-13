//
// Created by Oleksandr Malyarenko on 1/5/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBCard.h"


@interface NSString (Enum)


+ (NSString *)stringFromCardPermission:(PBCardPermission)permission;

+ (NSString *)stringFromPhoneType:(PBPhoneType)phoneType;

+ (NSString *)stringFromEmailType:(PBEmailType)emailType;

+ (NSString *)stringFromUrlType:(PBUrlType)urlType;

@end