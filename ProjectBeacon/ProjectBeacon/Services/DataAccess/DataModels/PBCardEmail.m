//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBCardEmail.h"
#import "PBWebContact.h"


@implementation PBCardEmail {

}


- (void)fromWebModel:(PBWebBaseModel *)model {
    self.id = ((PBWebContact *) model).id;
    self.email = ((PBWebContact *) model).data;
    self.emailType = (PBEmailType) ((PBWebContact *) model).contactType;
}

@end