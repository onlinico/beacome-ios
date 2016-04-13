//
// Created by Oleksandr Malyarenko on 11/30/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <objc/runtime.h>
#import "PBBaseModel.h"
#import "PBWebBaseModel.h"


@implementation PBBaseModel {

}


- (instancetype)initWithDatabaseResultSet:(FMResultSet *)resultSet {
    self = [super init];
    if (self) {
        unsigned int propertyCount = 0;
        objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);

        for (unsigned int i = 0; i < propertyCount; ++i) {
            objc_property_t property = properties[i];
            NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
            id value = [[resultSet objectForColumnName:propertyName] isKindOfClass:[NSNull class]] ? nil : [resultSet objectForColumnName:propertyName];
            if (![resultSet columnIsNull:propertyName]) {
                [self setValue:value forKey:propertyName];
            }
        }
        free(properties);
    }

    return self;
}


- (void)fromWebModel:(PBWebBaseModel *)model {
}

@end