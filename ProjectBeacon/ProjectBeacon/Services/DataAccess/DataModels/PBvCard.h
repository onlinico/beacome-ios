//
// Created by Oleksandr Malyarenko on 11/27/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseModel.h"


@interface PBVCard : PBBaseModel


@property (nonatomic, assign) NSInteger id;
@property (nonatomic, strong) NSString *cardId;
@property (nonatomic, strong) NSData *personImage;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, assign) NSInteger version;
@property (nonatomic, strong) NSString *vCardData;


- (void)importVCardIntoNativeContactsWithCallback:(void (^)(id contact))callback;

- (void)createVCardData;

@end