//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBWebUser.h"
#import "PBUser.h"


@implementation PBWebUser {

}


- (void)fromLocalModel:(PBBaseModel *)model {
    PBUser *userModel = (PBUser *) model;
    self.id = userModel.userId;
    self.name = userModel.fullName ? userModel.fullName : @"";
    self.email = userModel.email ? userModel.email : @"";
    self.photo = userModel.userPicture ? [userModel.userPicture base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed] : @"";
}

@end