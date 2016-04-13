//
// Created by Oleksandr Malyarenko on 12/1/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBBeacon.h"
#import "PBWebBeacon.h"
#import "PBWebBeaconCard.h"
#import "PBBeaconCard.h"


@interface PBBeacon () <NSCopying>
@end


@implementation PBBeacon {

}


- (instancetype)initWithCLBeacon:(CLBeacon *)beacon {
    if (self = [super init]) {
        self.beaconUid = beacon.proximityUUID.UUIDString;
        self.major = [beacon.major integerValue];
        self.minor = [beacon.minor integerValue];
        self.power = beacon.rssi;
    }

    return self;
}


- (void)fromWebModel:(PBWebBaseModel *)model {
    PBWebBeacon *webBeacon = (PBWebBeacon *) model;
    self.beaconUid = [webBeacon.uid uppercaseString];
    self.major = webBeacon.major;
    self.minor = webBeacon.minor;
    self.power = webBeacon.powerLevel;

    NSMutableArray *beaconCards = [NSMutableArray array];
    for (PBWebBeaconCard *webBeaconCard in webBeacon.cards) {
        PBBeaconCard *beaconCard = [[PBBeaconCard alloc] init];
        [beaconCard fromWebModel:webBeaconCard];
        [beaconCards addObject:beaconCard];
    }
    self.cards = beaconCards;

    self.version = webBeacon.timestamp;
    self.linkedCardsCount = self.cards.count;
}


- (BOOL)isEqual:(id)object {
    return !object || ![object isKindOfClass:[self class]] ? NO : [self.beaconUid isEqualToString:((PBBeacon *) object).beaconUid];
}


- (id)copyWithZone:(NSZone *)zone {
    PBBeacon *copy = (PBBeacon *) [[[PBBeacon class] allocWithZone:zone] init];
    copy.cards = self.cards;
    copy.beaconUid = self.beaconUid;
    copy.major = self.major;
    copy.minor = self.minor;
    copy.power = self.power;
    copy.state = self.state;
    copy.linkedCardsCount = self.linkedCardsCount;
    copy.version = self.version;
    return copy;
}

@end