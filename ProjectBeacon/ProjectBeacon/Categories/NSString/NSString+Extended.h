//
// Created by Oleksandr Malyarenko on 1/19/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Extended)


+ (BOOL)isEmptyOrNil:(NSString *)string;

+ (BOOL)validateEmail:(NSString *)email;
+ (BOOL)validatePhone:(NSString *)phoneNumber;
+ (BOOL)validateURL:(NSString *)url;
@end