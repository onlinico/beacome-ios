//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBWebContact.h"
#import "PBCardPhone.h"
#import "PBCardEmail.h"
#import "PBCardURL.h"


@implementation PBWebContact {

}


- (void)fromLocalModel:(PBBaseModel *)model {
    if ([model isMemberOfClass:[PBCardPhone class]]) {
        self.id = ((PBCardPhone *) model).id;
        self.data = ((PBCardPhone *) model).phoneNumber;
        self.contactType = ((PBCardPhone *) model).phoneType;
    }
    else if ([model isMemberOfClass:[PBCardEmail class]]) {
        self.id = ((PBCardEmail *) model).id;
        self.data = ((PBCardEmail *) model).email;
        self.contactType = ((PBCardEmail *) model).emailType;
    }
    else {
        self.id = ((PBCardURL *) model).id;
        self.data = ((PBCardURL *) model).url;
        self.contactType = ((PBCardURL *) model).urlType;
    }
}

@end