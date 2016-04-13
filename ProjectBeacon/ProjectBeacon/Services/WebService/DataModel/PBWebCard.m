//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBWebCard.h"
#import "PBWebContact.h"
#import "PBWebVCard.h"
#import "PBCard.h"
#import "PBVCard.h"
#import "PBWebCardsShare.h"


@implementation PBWebCard {

}


+ (RKMapping *)mapping {

    RKObjectMapping *mapping = (RKObjectMapping *) [super mapping];

    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"Contacts" toKeyPath:@"contacts" withMapping:[PBWebContact mapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"VCards" toKeyPath:@"vCards" withMapping:[PBWebVCard mapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"Users" toKeyPath:@"users" withMapping:[PBWebCardsShare mapping]]];

    return mapping;
}


- (void)fromLocalModel:(PBBaseModel *)model {
    PBCard *cardModel = (PBCard *) model;
    self.guid = cardModel.cardId;
    self.title = cardModel.title;
    self.desc = cardModel.summary;
    self.timestamp = cardModel.version;
    self.logo = cardModel.logo ? [cardModel.logo base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed] : @"";

    NSMutableArray *contacts = [NSMutableArray array];
    NSMutableArray *vCards = [NSMutableArray array];
    for (PBCardPhone *phone in cardModel.phones) {
        PBWebContact *contact = [[PBWebContact alloc] init];
        [contact fromLocalModel:phone];
        [contacts addObject:contact];
    }
    for (PBCardEmail *email in cardModel.emails) {
        PBWebContact *contact = [[PBWebContact alloc] init];
        [contact fromLocalModel:email];
        [contacts addObject:contact];
    }
    for (PBCardURL *url in cardModel.urls) {
        PBWebContact *contact = [[PBWebContact alloc] init];
        [contact fromLocalModel:url];
        [contacts addObject:contact];
    }
    for (PBVCard *vCard in cardModel.vCards) {
        PBWebVCard *webVCard = [[PBWebVCard alloc] init];
        [webVCard fromLocalModel:vCard];
        [vCards addObject:webVCard];
    }
    self.vCards = vCards;
    self.contacts = contacts;
    self.users = [NSArray array];
}

@end