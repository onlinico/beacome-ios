//
// Created by Oleksandr Malyarenko on 11/27/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBUser.h"
#import "PBWebUser.h"


@implementation PBUser {

}


- (void)fromWebModel:(PBWebBaseModel *)model {
    PBWebUser *webUser = (PBWebUser *) model;

    self.userId = webUser.id;
    self.fullName = [webUser.name isMemberOfClass:[NSNull class]] ? nil : webUser.name;
    self.email = [webUser.email isMemberOfClass:[NSNull class]] ? nil : webUser.email;
    self.userPicture = webUser.photo ? [[NSData alloc] initWithBase64EncodedString:webUser.photo options:NSDataBase64DecodingIgnoreUnknownCharacters] : nil;
}

@end