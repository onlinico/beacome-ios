//
// Created by Oleksandr Malyarenko on 2/5/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import "PBLinkSocial.h"
#import "PBWebUserSocial.h"


@implementation PBLinkSocial {

}


- (void)fromWebModel:(PBWebBaseModel *)model {
    PBWebUserSocial *socialLinks = (PBWebUserSocial *) model;
    self.facebook = socialLinks.facebook;
    self.twitter = socialLinks.twitter;
    self.google = socialLinks.google;
}

@end