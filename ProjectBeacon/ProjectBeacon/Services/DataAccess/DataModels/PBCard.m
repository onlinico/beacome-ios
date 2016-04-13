//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBCard.h"
#import "PBWebCard.h"
#import "PBWebContact.h"
#import "PBWebVCard.h"
#import "PBVCard.h"
#import "PBCardHistory.h"
#import "NSString+Extended.h"
#import "PBWebCardsShare.h"
#import "PBCardsShare.h"
#import "PBApplicationFacade.h"


@interface PBCard () <NSCopying>


@property (nonatomic, assign) NSTimeInterval visitDateTimeStamp;
@end


@implementation PBCard {

}


- (instancetype)initWithDatabaseResultSet:(FMResultSet *)resultSet {
    if (self = [super initWithDatabaseResultSet:resultSet]) {
        self.visitDate = [NSDate dateWithTimeIntervalSince1970:self.visitDateTimeStamp];
    }

    return self;
}


- (void)fromWebModel:(PBWebBaseModel *)model {
    PBWebCard *webCard = (PBWebCard *) model;
    self.cardId = webCard.guid;
    self.title = webCard.title;
    self.summary = webCard.desc;
    self.version = webCard.timestamp;
    self.beaconsCount = webCard.beaconsCount;
    self.logo = [NSString isEmptyOrNil:webCard.logo] ? nil : [[NSData alloc] initWithBase64EncodedString:webCard.logo options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSMutableArray *phones = [NSMutableArray array];
    NSMutableArray *emails = [NSMutableArray array];
    NSMutableArray *urls = [NSMutableArray array];
    NSMutableArray *vCards = [NSMutableArray array];
    NSMutableArray *users = [NSMutableArray array];

    for (PBWebContact *contact in webCard.contacts) {
        if (contact.contactType > 100 && contact.contactType < 200) {
            PBCardPhone *phone = [[PBCardPhone alloc] init];
            [phone fromWebModel:contact];
            [phones addObject:phone];
        }
        else if (contact.contactType > 200 && contact.contactType < 300) {
            PBCardEmail *email = [[PBCardEmail alloc] init];
            [email fromWebModel:contact];
            [emails addObject:email];
        }
        else {
            PBCardURL *url = [[PBCardURL alloc] init];
            [url fromWebModel:contact];
            [urls addObject:url];
        }
    }
    for (PBWebVCard *webVCard in webCard.vCards) {
        PBVCard *vCard = [[PBVCard alloc] init];
        [vCard fromWebModel:webVCard];
        [vCards addObject:vCard];
    }
    for (PBWebCardsShare *webCardsShare in webCard.users) {
        PBCardsShare *cardsShare = [[PBCardsShare alloc] init];
        [cardsShare fromWebModel:webCardsShare];

        if (cardsShare.userId == [[PBApplicationFacade sharedManager] userId]) {
            self.permission = cardsShare.permission;
        }
        else {
            [users addObject:cardsShare];
        }
    }

    self.phones = phones;
    self.emails = emails;
    self.urls = urls;
    self.vCards = vCards;
    self.cardShare = users;
}


- (NSInteger)beaconsCount {
    return _beaconsCount ? _beaconsCount : self.beacons.count;
}


- (void)setupCardHistory:(PBCardHistory *)cardHistory {
    _visitDate = cardHistory.visitDate;
    _isFavourite = cardHistory.isFavourite;
}


- (BOOL)isEqual:(id)object {
    return !object || ![object isKindOfClass:[self class]] ? NO : [self.cardId isEqualToString:((PBCard *) object).cardId];
}

- (NSUInteger)hash {
    return [self.cardId hash];
}


- (id)copyWithZone:(NSZone *)zone {
    PBCard *copy = (PBCard *) [[[PBCard class] allocWithZone:zone] init];
    copy.cardId = self.cardId;
    copy.cardShare = [[NSArray alloc] initWithArray:self.cardShare copyItems:YES];;
    copy.isActive = self.isActive;
    copy.beacons = [[NSArray alloc] initWithArray:self.beacons copyItems:YES];;
    copy.beaconsCount = self.beaconsCount;
    copy.emails = self.emails;
    copy.permission = self.permission;
    copy.phones = self.phones;
    copy.urls = self.urls;
    copy.title = self.title;
    copy.summary = self.summary;
    copy.vCards = self.vCards;
    copy.logo = self.logo;
    copy.shortInfo = self.shortInfo;
    copy.version = self.version;
    copy.visitDate = self.visitDate;
    copy.isFavourite = self.isFavourite;

    return copy;
}

@end