//
// Created by Oleksandr Malyarenko on 12/21/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBWebCardsShare.h"
#import "PBCardsShare.h"


@implementation PBWebCardsShare {

}


- (void)fromLocalModel:(PBBaseModel *)model {
    PBCardsShare *cardsShare = (PBCardsShare *) model;
    self.id = cardsShare.userId;
    self.isOwner = cardsShare.permission;
    self.shareGuid = cardsShare.shareGuid;
}

@end