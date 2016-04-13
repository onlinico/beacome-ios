//
// Created by Oleksandr Malyarenko on 1/5/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import "NSString+Enum.h"


@implementation NSString (Enum)


+ (NSString *)stringFromCardPermission:(PBCardPermission)permission {
    NSString *result = nil;
    switch (permission) {
        case PBCardPermissionOwner: {
            result = NSLocalizedString(@"Owner", @"Owner");
            break;
        }
        case PBCardPermissionTranslator: {
            result = NSLocalizedString(@"Translator", @"Translator");
            break;
        }
    }
    return result;
}


+ (NSString *)stringFromPhoneType:(PBPhoneType)phoneType {
    NSString *result = nil;
    switch (phoneType) {

        case PBPhoneTypeMobile: {
            result = NSLocalizedString(@"Mobile Phone", @"Mobile Phone");
            break;
        }
        case PBPhoneTypeHome: {
            result = NSLocalizedString(@"Home Phone", @"Home Phone");
            break;
        }
        case PBPhoneTypeWork: {
            result = NSLocalizedString(@"Work Phone", @"Work Phone");
            break;
        }
        case PBPhoneTypeCompany: {
            result = NSLocalizedString(@"Company Phone", @"Company Phone");
            break;
        }
        case PBPhoneTypeFax: {
            result = NSLocalizedString(@"Fax", @"Fax");
            break;
        }
        case PBPhoneTypeOther: {
            result = NSLocalizedString(@"Other", @"Other");
            break;
        }
    }

    return result;
}


+ (NSString *)stringFromEmailType:(PBEmailType)emailType {
    NSString *result = nil;
    switch (emailType) {

        case PBEmailTypePersonal: {
            result = NSLocalizedString(@"Personal Email", @"Personal Email");
            break;
        }
        case PBEmailTypeWork: {
            result = NSLocalizedString(@"Work Email", @"Work Email");
            break;
        }
        case PBEmailTypeOther: {
            result = NSLocalizedString(@"Other", @"Other");
            break;
        }
    }

    return result;
}


+ (NSString *)stringFromUrlType:(PBUrlType)urlType {
    NSString *result = nil;
    switch (urlType) {

        case PBUrlWebsite: {
            result = NSLocalizedString(@"Website", @"Website");
            break;
        }
        case PBUrlSkype: {
            result = NSLocalizedString(@"Skype", @"Skype");
            break;
        }
    }
    return result;
}

@end