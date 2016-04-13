//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBCardURL.h"
#import "PBWebContact.h"


@implementation PBCardURL {

}


- (void)fromWebModel:(PBWebBaseModel *)model {
    self.id = ((PBWebContact *) model).id;
    self.url = ((PBWebContact *) model).data;
    self.urlType = (PBUrlType) ((PBWebContact *) model).contactType;
}

@end