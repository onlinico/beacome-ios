//
// Created by Oleksandr Malyarenko on 12/8/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <objc/runtime.h>
#import "PBWebBaseModel.h"
#import "PBBaseModel.h"


const char *property_getTypeString(objc_property_t property) {
    const char *attrs = property_getAttributes(property);
    if (attrs == NULL) {
        return (NULL);
    }

    static char buffer[256];
    const char *e = strchr(attrs, ',');
    if (e == NULL) {
        return (NULL);
    }

    int len = (int) (e - attrs);
    memcpy(buffer, attrs, len);
    buffer[len] = '\0';

    return (buffer);
}


@implementation PBWebBaseModel {

}


+ (RKMapping *)mapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[self class]];
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);

    NSMutableDictionary *propsDict = [NSMutableDictionary dictionary];
    for (unsigned int i = 0; i < propertyCount; ++i) {
        objc_property_t property = properties[i];
        NSString *tempPropName = [NSString stringWithUTF8String:property_getName(property)];
        NSString *propertyName = [NSString stringWithFormat:@"%@%@", [[tempPropName substringToIndex:1] uppercaseString], [tempPropName substringFromIndex:1]];
        NSString *propertyType = [NSString stringWithUTF8String:property_getTypeString(property)];
        if (![propertyType isEqualToString:@"T@\"NSArray\""]) {
            if ([tempPropName isEqualToString:@"desc"]) {
                propsDict[@"Description"] = tempPropName;
            }
            else {
                propsDict[propertyName] = tempPropName;
            }

        }
    }
    free(properties);
    [mapping addAttributeMappingsFromDictionary:propsDict];
    mapping.assignsNilForMissingRelationships = YES;
    mapping.assignsDefaultValueForMissingAttributes = YES;

    return mapping;
}


+ (RKMapping *)requestMapping {
    RKObjectMapping *requestMapping = (RKObjectMapping *) [self mapping];

    return [requestMapping inverseMapping];
}


- (void)fromLocalModel:(PBBaseModel *)model {

}

@end