//
// Created by Oleksandr Malyarenko on 11/27/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBaseModel.h"


@interface PBUser : PBBaseModel


@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, strong) NSData *userPicture;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, assign) BOOL facebookIsLinked;
@property (nonatomic, assign) BOOL twitterIsLinked;
@property (nonatomic, assign) BOOL gPlusIsLinked;

@end