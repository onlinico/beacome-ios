//
// Created by Oleksandr Malyarenko on 2/4/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import "PBVCardModel.h"
#import "PBvCard.h"


@implementation PBVCardModel {

}


static NSInteger itemCounter;


+ (NSInteger)itemCounter {
    return itemCounter;
};


+ (void)setItemCounter:(NSInteger)value {
    itemCounter = value;
};


+ (NSString *)generateVCardStringWithRec:(PBVCard *)rec {
    [PBVCardModel setItemCounter:0];
    NSString *vcard = @"BEGIN:VCARD\nVERSION:3.0\n";

    NSArray *nameParts = [rec.fullName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *nameString = [NSString string];
    switch (nameParts.count){
        case 1:{
            nameString = nameParts[0];
            break;
        }
        case 2:{
            nameString = [NSString stringWithFormat:@"%@;%@", nameParts[1], nameParts[0]];
            break;
        }
        case 3:{
            nameString = [NSString stringWithFormat:@"%@;%@;%@", nameParts[2], nameParts[0], nameParts[1]];
            break;
        }
        default:{
            nameString = [rec.fullName mutableCopy];
            break;
        }
    }
    // Name
    vcard = [vcard stringByAppendingFormat:@"N:%@;\n", (nameString ? nameString : @"")];


    // Mail
    vcard = [vcard stringByAppendingString:[PBVCardModel toVcardField:@"email" items:@[rec.email] labels:@[@"Work"]]];

    // Tel
    vcard = [vcard stringByAppendingString:[PBVCardModel toVcardField:@"phone" items:@[rec.phone] labels:@[@"Work"]]];

    // Photo
    NSData *imageData = rec.personImage;//contact.imageData;
    if (imageData) {
        vcard = [vcard stringByAppendingFormat:@"PHOTO;BASE64:%@\n", [imageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn]];
    }

    // end
    vcard = [vcard stringByAppendingString:@"END:VCARD"];

    return vcard;
}


+ (NSString *)toVcardField:(NSString *)type items:(NSArray *)items labels:(NSArray *)labels {
    if (!items) {
        return @"";
    }

    NSString *vcard = @"";

    if ([items count] > 0) {
        NSInteger len = [items count];
        for (int i = 0; i < len; i++) {
            if ([type isEqualToString:@"email"]) {
                vcard = [vcard stringByAppendingString:[PBVCardModel emailToVcardField:items[i] label:labels[i]]];
            }
            else if ([type isEqualToString:@"phone"]) {
                vcard = [vcard stringByAppendingString:[PBVCardModel phoneToVcardField:items[i] label:labels[i]]];
            }
            else if ([type isEqualToString:@"address"]) {
                vcard = [vcard stringByAppendingString:[PBVCardModel addressToVcardField:items[i] label:labels[i]]];
            }
            else if ([type isEqualToString:@"url"]) {
                vcard = [vcard stringByAppendingString:[PBVCardModel urlToVcardField:items[i] label:labels[i]]];
            }
            else if ([type isEqualToString:@"im"]) {
                vcard = [vcard stringByAppendingString:[PBVCardModel imToVcardField:items[i] label:labels[i]]];
            }
        }
    }

    return vcard;
}


+ (NSString *)emailToVcardField:(NSString *)email label:(NSString *)label {
    NSString *labelLower = [label lowercaseString];
    NSString *vcard = @"";

    if ([labelLower isEqualToString:@"_$!<home>!$_"]) {
        vcard = [NSString stringWithFormat:@"EMAIL;type=INTERNET;type=HOME:%@\n", email];
    }
    else if ([labelLower isEqualToString:@"_$!<work>!$_"]) {
        vcard = [NSString stringWithFormat:@"EMAIL;type=INTERNET;type=WORK:%@\n", email];
    }
    else {
        NSInteger counter = [PBVCardModel itemCounter] + 1;
        vcard = [NSString stringWithFormat:@"item%ld.EMAIL;type=INTERNET:%@\nitem%ld.X-ABLabel:%@\n", (long)counter, email, (long)counter, label];
        [PBVCardModel setItemCounter:counter];
    }

    return vcard;
}


+ (NSString *)phoneToVcardField:(NSString *)phone label:(NSString *)label {
    //_$!<Mobile>!$_, iPhone, _$!<Home>!$_, _$!<Work>!$_, _$!<Main>!$_, _$!<HomeFAX>!$_, _$!<WorkFAX>!$_, _$!<Pager>!$_

    NSString *labelLower = [label lowercaseString];
    NSString *vcard = @"";

    if ([labelLower isEqualToString:@"_$!<mobile>!$_"]) {
        vcard = [NSString stringWithFormat:@"TEL;type=CELL:%@\n", phone];
    }
    else if ([labelLower isEqualToString:@"iphone"]) {
        vcard = [NSString stringWithFormat:@"TEL;type=IPHONE:%@\n", phone];
    }
    else if ([labelLower isEqualToString:@"_$!<home>!$_"]) {
        vcard = [NSString stringWithFormat:@"TEL;type=HOME:%@\n", phone];
    }
    else if ([labelLower isEqualToString:@"_$!<work>!$_"]) {
        vcard = [NSString stringWithFormat:@"TEL;type=WORK:%@\n", phone];
    }
    else if ([labelLower isEqualToString:@"_$!<main>!$_"]) {
        vcard = [NSString stringWithFormat:@"TEL;type=MAIN:%@\n", phone];
    }
    else if ([labelLower isEqualToString:@"_$!<homefax>!$_"]) {
        vcard = [NSString stringWithFormat:@"TEL;type=HOME;type=FAX:%@\n", phone];
    }
    else if ([labelLower isEqualToString:@"_$!<workfax>!$_"]) {
        vcard = [NSString stringWithFormat:@"TEL;type=WORK;type=FAX:%@\n", phone];
    }
    else if ([labelLower isEqualToString:@"_$!<pager>!$_"]) {
        vcard = [NSString stringWithFormat:@"TEL;type=PAGER:%@\n", phone];
    }
    else {
        NSInteger counter = [PBVCardModel itemCounter] + 1;
        vcard = [NSString stringWithFormat:@"item%ld.TEL:%@\nitem%ld.X-ABLabel:%@\n", (long)counter, phone, (long)counter, label];
        [PBVCardModel setItemCounter:counter];
    }

    return vcard;
}


+ (NSString *)addressToVcardField:(NSDictionary *)address label:(NSString *)label {
    NSString *vcard = @"";
    NSString *labelField = @"";
    NSString *labelLower = [label lowercaseString];
    NSString *type = @"HOME";

    NSInteger counter = [PBVCardModel itemCounter] + 1;

    //
    if ([labelLower isEqualToString:@"_$!<work>!$_"]) {
        type = @"WORK";
    }
    else if ([labelLower isEqualToString:@"_$!<home>!$_"]) {
    }
    else if (label && [label length] > 0) {
        labelField = [NSString stringWithFormat:@"item%ld.X-ABLabel:%@\n", (long)counter, label];
    }

    //
    NSString *street = address[@"Street"] ? address[@"Street"] : @"";
    if ([street rangeOfString:@"\n"].location != NSNotFound) {
        NSArray *arr = [street componentsSeparatedByString:@"\n"];
        street = [arr componentsJoinedByString:@"\\n"];
    }

    NSString *City = address[@"City"] ? address[@"City"] : @"";
    NSString *State = address[@"State"] ? address[@"State"] : @"";
    NSString *ZIP = address[@"ZIP"] ? address[@"ZIP"] : @"";
    NSString *Country = address[@"Country"] ? address[@"Country"] : @"";
    NSString *CountryCode = address[@"CountryCode"] ? address[@"CountryCode"] : @"";


    //
    vcard = [NSString stringWithFormat:@"item%ld.ADR;type=%@:;;%@;%@;%@;%@;%@\n%@item%ld.X-ABADR:%@\n", (long)counter, type, street, City, State, ZIP, Country, labelField, (long)counter, CountryCode];

    //
    [PBVCardModel setItemCounter:counter];

    return vcard;
}


+ (NSString *)urlToVcardField:(NSString *)url label:(NSString *)label {
    NSString *labelLower = [label lowercaseString];
    NSString *vcard = @"";

    if ([labelLower isEqualToString:@"_$!<home>!$_"]) {
        vcard = [NSString stringWithFormat:@"URL;type=HOME:%@\n", url];
    }
    else if ([labelLower isEqualToString:@"_$!<work>!$_"]) {
        vcard = [NSString stringWithFormat:@"URL;type=WORK:%@\n", url];
    }
    else {
        NSInteger counter = [PBVCardModel itemCounter] + 1;
        vcard = [NSString stringWithFormat:@"item%ld.URL:%@\nitem%ld.X-ABLabel:%@\n", (long)counter, url, (long)counter, label];
        [PBVCardModel setItemCounter:counter];
    }

    return vcard;
}


+ (NSString *)imToVcardField:(NSDictionary *)im label:(NSString *)label {
    NSString *labelLower = [label lowercaseString];
    NSString *vcard = @"";

    NSString *service = im[@"service"] ? im[@"service"] : @"";
    service = [service uppercaseString];

    NSString *username = im[@"username"] ? im[@"username"] : @"";

    //
    if ([labelLower isEqualToString:@"_$!<home>!$_"] || [labelLower isEqualToString:@"_$!<work>!$_"]) {
        NSString *type = [labelLower isEqualToString:@"_$!<home>!$_"] ? @"HOME" : @"WORK";
        vcard = [NSString stringWithFormat:@"X-%@;type=%@:%@\n", service, type, username];
    }

    else {
        NSInteger counter = [PBVCardModel itemCounter] + 1;
        vcard = [NSString stringWithFormat:@"item%ld.X-%@:%@\nitem%ld.X-ABLabel:%@\n", (long)counter, service, username, (long)counter, label];
        [PBVCardModel setItemCounter:counter];
    }

    return vcard;
}

@end