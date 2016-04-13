//
// Created by Oleksandr Malyarenko on 2/4/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>


@class PBVCard;


@interface PBVCardModel : NSObject


+ (NSString *)generateVCardStringWithRec:(PBVCard *)rec;
@end