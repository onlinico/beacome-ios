//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBWebBeaconCard.h"
#import "PBBeaconCard.h"


@implementation PBWebBeaconCard {

}


- (void)fromLocalModel:(PBBaseModel *)model {
    PBBeaconCard *beaconCard = (PBBeaconCard *) model;
    self.cardGuid = beaconCard.cardGuid;
    self.isActive = beaconCard.isActive;
}

@end