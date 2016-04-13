//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBCardPhone.h"
#import "PBWebBaseModel.h"
#import "PBWebContact.h"


@implementation PBCardPhone {

}


- (void)fromWebModel:(PBWebBaseModel *)model {
    self.id = ((PBWebContact *) model).id;
    self.phoneNumber = ((PBWebContact *) model).data;
    self.phoneType = (PBPhoneType) ((PBWebContact *) model).contactType;
}

@end