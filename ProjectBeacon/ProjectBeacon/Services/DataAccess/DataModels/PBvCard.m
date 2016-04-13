//
// Created by Oleksandr Malyarenko on 11/27/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>
#import "PBVCard.h"
#import "PBWebVCard.h"
#import "NSString+Extended.h"
#import "PBVCardModel.h"


@implementation PBVCard {

}


- (void)fromWebModel:(PBWebBaseModel *)model {
    PBWebVCard *webVCard = (PBWebVCard *) model;
    self.id = webVCard.id;
    self.fullName = webVCard.name;
    self.email = webVCard.email;
    self.phone = webVCard.phone;
    self.personImage = [NSString isEmptyOrNil:webVCard.photo] ? nil : [[NSData alloc] initWithBase64EncodedString:webVCard.photo options:NSDataBase64DecodingIgnoreUnknownCharacters];;
    self.vCardData = webVCard.vCardData;
}


- (void)importVCardIntoNativeContactsWithCallback:(void (^)(id contact))callback {
    NSOperatingSystemVersion systemVersion;
    systemVersion.majorVersion = 9;
    systemVersion.minorVersion = 0;
    systemVersion.patchVersion = 0;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:systemVersion]) {
        CNContactStore *store = [[CNContactStore alloc] init];
        if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] != CNAuthorizationStatusAuthorized) {
            [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error) {
                if (!granted) {
                    if (callback) {
                        callback(nil);
                    }
                    return;
                }
                NSError *serializationError = nil;
                NSArray *contacts = [CNContactVCardSerialization contactsWithData:[self.vCardData dataUsingEncoding:NSUTF8StringEncoding] error:&serializationError];
                if (callback) {
                    callback(serializationError ? nil : contacts.firstObject);
                }
            }];
        }
        else {
            NSError *serializationError = nil;
            NSArray *contacts = [CNContactVCardSerialization contactsWithData:[self.vCardData dataUsingEncoding:NSUTF8StringEncoding] error:&serializationError];
            if (callback) {
                callback(serializationError ? nil : contacts.firstObject);
            }
        }
    }
    else {
        CFDataRef vCardData = (__bridge CFDataRef) [self.vCardData dataUsingEncoding:NSUTF8StringEncoding];

        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
                ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(addressBookRef);
                CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, vCardData);
                ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, 0);
                
                CFRelease(vCardPeople);
                CFRelease(defaultSource);
                CFRelease(addressBookRef);
                if (callback) {
                    callback(CFBridgingRelease(person));
                }
            });
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(addressBookRef);
            CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, vCardData);
            ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, 0);
            
            CFRelease(vCardPeople);
            CFRelease(defaultSource);
            CFRelease(addressBookRef);
            if (callback) {
                callback(CFBridgingRelease(person));
            }
        }

    }

}


- (void)createVCardData {
    NSString *dataString = [PBVCardModel generateVCardStringWithRec:self];
    if (![NSString isEmptyOrNil:dataString]) {
        self.vCardData = dataString;
    }
}

@end