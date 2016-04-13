//
// Created by Oleksandr Malyarenko on 12/21/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBCardsShare.h"
#import "PBWebCardsShare.h"
#import "NSString+Extended.h"


@interface PBCardsShare () <NSCopying>
@end


@implementation PBCardsShare {

}


- (void)fromWebModel:(PBWebBaseModel *)model {
    PBWebCardsShare *webModel = (PBWebCardsShare *) model;
    self.email = webModel.email;
    self.permission = webModel.isOwner;
    self.userId = webModel.id;
    self.shareGuid = webModel.shareGuid;
    self.name = webModel.name;
    self.photo = [NSString isEmptyOrNil:webModel.photo] ? nil : [[NSData alloc] initWithBase64EncodedString:webModel.photo options:NSDataBase64DecodingIgnoreUnknownCharacters];
}


- (BOOL)isEqual:(id)object {
    return !object || ![object isKindOfClass:[self class]] ? NO : ([self.shareGuid isEqualToString:((PBCardsShare *) object).shareGuid] && (self.id == ((PBCardsShare *) object).id));
}


- (id)copyWithZone:(NSZone *)zone {
    PBCardsShare *copy = (PBCardsShare *) [[[PBCardsShare class] allocWithZone:zone] init];
    copy.email = self.email;
    copy.id = self.id;
    copy.userId = self.userId;
    copy.shareGuid = self.shareGuid;
    copy.name = self.name;
    copy.photo = self.photo;
    copy.permission = self.permission;
    return copy;
}

@end