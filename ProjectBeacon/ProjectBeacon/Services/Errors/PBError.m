//
// Created by Oleksandr Malyarenko on 2/6/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import "PBError.h"


static const unsigned long long kPBInternetConnectionErrorCode = 18446744073709550607;


@implementation PBError


+ (NSString *)localizedDescriptionForKey:(NSString *)key {
    return NSLocalizedString(key, nil);
}


+ (NSError *)checkAndCreateInApplicationError:(NSError *)externalError {
    NSError *error = nil;
    if ([externalError.domain isEqualToString:@"org.restkit.RestKit.ErrorDomain"]) {
        error = [NSError errorWithDomain:kPBErrorDomain code:kPBWebserviceErrorCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBWebserviceError]}];
    }
    else if ([externalError.domain isEqualToString:NSURLErrorDomain] && externalError.code == kPBInternetConnectionErrorCode) {
        error = [NSError errorWithDomain:kPBErrorDomain code:kPBWebserviceConnectionErrorCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBWebserviceConnectionError]}];
    }
    else{
        error = externalError;
    }

    return error;
}

@end