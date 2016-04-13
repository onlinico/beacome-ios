//
// Created by Oleksandr Malyarenko on 12/1/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBCardHistory.h"


@interface PBCardHistory ()


@property (nonatomic, assign) NSTimeInterval visitDateTimeStamp;

@end


@implementation PBCardHistory {

}


- (instancetype)initWithDatabaseResultSet:(FMResultSet *)resultSet {
    if (self = [super initWithDatabaseResultSet:resultSet]) {
        self.visitDate = [NSDate dateWithTimeIntervalSince1970:self.visitDateTimeStamp];
    }

    return self;
}

@end