//
// Created by Oleksandr Malyarenko on 11/30/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>


#define GUID NSString


@interface NSString (GUID)


+ (GUID *)createGUID;
- (BOOL)isEqualToGUID:(GUID *)aString;
@end