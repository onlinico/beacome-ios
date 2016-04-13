//
// Created by Oleksandr Malyarenko on 1/19/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import "NSString+Extended.h"


@implementation NSString (Extended)


+ (BOOL)isEmptyOrNil:(NSString *)string {
    if (!string) {
        return YES;
    }
    NSString *temp = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [temp isEqualToString:@""];
}


+ (BOOL)validateEmail:(NSString *)email {
    NSString *emailRegex = @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
            @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
            @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
            @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
            @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
            @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
            @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];

    return [emailTest evaluateWithObject:email];
}


+ (BOOL)validatePhone:(NSString *)phoneNumber {
    NSUInteger length = [phoneNumber length];
    if (length > 0) {
        NSError *error = nil;
        NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
        if (dataDetector && !error) {
            NSRange range = NSMakeRange(0, length);
            NSRange notFoundRange = (NSRange) {NSNotFound, 0};
            NSRange linkRange = [dataDetector rangeOfFirstMatchInString:phoneNumber options:0 range:range];
            if (!NSEqualRanges(notFoundRange, linkRange) && NSEqualRanges(range, linkRange)) {
                return YES;
            }
        }
    }

    return NO;
}


+ (BOOL)validateURL:(NSString *)url {
    NSUInteger length = [url length];
    if (length > 0) {
        NSError *error = nil;
        NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
        if (dataDetector && !error) {
            NSRange range = NSMakeRange(0, length);
            NSRange notFoundRange = (NSRange) {NSNotFound, 0};
            NSRange linkRange = [dataDetector rangeOfFirstMatchInString:url options:0 range:range];
            if (!NSEqualRanges(notFoundRange, linkRange) && NSEqualRanges(range, linkRange)) {
                return YES;
            }
        }
    }

    return NO;
}

@end