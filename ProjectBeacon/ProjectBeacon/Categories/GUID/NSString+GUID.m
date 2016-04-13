//
// Created by Oleksandr Malyarenko on 11/30/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "NSString+GUID.h"


@implementation NSString (GUID)


+ (GUID *)createGUID {
    CFUUIDRef UUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, UUID);
    CFRelease(UUID);
    GUID *newGUID = [[GUID alloc] initWithString:(__bridge NSString *) string];
    CFRelease(string);
    return newGUID;
}


- (BOOL)isEqualToGUID:(GUID *)aString {
    return [self isEqualToString:aString];
}
@end