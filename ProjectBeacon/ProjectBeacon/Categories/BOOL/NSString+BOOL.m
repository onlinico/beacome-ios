//
// Created by Oleksandr Malyarenko on 12/9/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "NSString+BOOL.h"


@implementation NSString (BOOL)


+ (NSString *)stringFromBool:(BOOL)value {
    return value ? @"true" : @"false";
}

@end