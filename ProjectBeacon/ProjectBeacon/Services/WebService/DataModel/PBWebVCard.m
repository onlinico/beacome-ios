//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBWebVCard.h"
#import "PBVCard.h"


@implementation PBWebVCard {

}


- (void)fromLocalModel:(PBBaseModel *)model {
    PBVCard *vCardModel = (PBVCard *) model;
    self.id = vCardModel.id;
    self.timestamp = vCardModel.version;
    self.email = vCardModel.email;
    self.name = vCardModel.fullName;
    self.phone = vCardModel.phone;
    self.vCardData = vCardModel.vCardData;
    self.photo = vCardModel.personImage ? [vCardModel.personImage base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed] : @"";
}

@end