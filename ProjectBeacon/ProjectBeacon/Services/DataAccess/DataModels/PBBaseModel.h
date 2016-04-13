//
// Created by Oleksandr Malyarenko on 11/30/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMResultSet.h"


@class PBWebBaseModel;
@class PBWebUser;


@interface PBBaseModel : NSObject


- (instancetype)initWithDatabaseResultSet:(FMResultSet *)resultSet;

- (void)fromWebModel:(PBWebBaseModel *)model;

@end