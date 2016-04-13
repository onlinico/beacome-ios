//
//  PBBUtils.h
//  AnyiBeacon
//
//  Created by jaume on 30/04/14.
//  Copyright (c) 2014 Sandeep Mistry. All rights reserved.
//

@import Foundation;
@import CoreLocation;


@interface PBBUtils : NSObject


+ (NSString *)stringForProximityValue:(CLProximity)proximity;

@end
