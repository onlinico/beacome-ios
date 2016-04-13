//
// Created by Oleksandr Malyarenko on 1/8/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import "PBBeaconCard.h"
#import "PBWebBeaconCard.h"


@implementation PBBeaconCard {

}


- (void)fromWebModel:(PBWebBaseModel *)model {
    PBWebBeaconCard *beaconCard = (PBWebBeaconCard *) model;
    self.cardGuid = beaconCard.cardGuid;
    self.isActive = beaconCard.isActive;
}

@end