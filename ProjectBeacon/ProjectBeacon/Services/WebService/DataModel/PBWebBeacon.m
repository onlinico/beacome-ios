//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBWebBeacon.h"
#import "PBWebBeaconCard.h"
#import "PBBeacon.h"
#import "PBBeaconCard.h"


@implementation PBWebBeacon {

}


+ (RKMapping *)mapping {
    RKObjectMapping *mapping = (RKObjectMapping *) [super mapping];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"Cards" toKeyPath:@"cards" withMapping:[PBWebBeaconCard mapping]]];

    return mapping;
}


- (void)fromLocalModel:(PBBaseModel *)model {
    __block NSMutableArray *linkedCards = [NSMutableArray array];
    PBBeacon *beaconModel = (PBBeacon *) model;
    self.uid = [beaconModel.beaconUid uppercaseString];
    self.major = beaconModel.major;
    self.minor = beaconModel.minor;
    self.powerLevel = beaconModel.power;
    [beaconModel.cards enumerateObjectsUsingBlock:^(PBBeaconCard *object, NSUInteger index, BOOL *stop) {
        PBWebBeaconCard *webBeaconCard = [[PBWebBeaconCard alloc] init];
        [webBeaconCard fromLocalModel:object];
        [linkedCards addObject:webBeaconCard];
    }];
    self.cards = linkedCards;
}

@end