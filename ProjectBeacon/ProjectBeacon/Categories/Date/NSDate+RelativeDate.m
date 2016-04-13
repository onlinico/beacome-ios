//
// Created by Oleksandr Malyarenko on 12/29/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "NSDate+RelativeDate.h"


@implementation NSDate (RelativeDate)


- (NSString *)relativeDateString {
    NSCalendarUnit units = NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitMonth | NSCalendarUnitYear;

    // if `date` is before "now" (i.e. in the past) then the components will be positive
    NSDateComponents *components = [[NSCalendar currentCalendar] components:units fromDate:self toDate:[NSDate date] options:0];

    if(components.month > 0 || components.weekOfYear > 0 || components.day > 1){
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd MMMM yyyy"];
        return [formatter stringFromDate:self];
    }
    if (components.day == 1) {
            return NSLocalizedString(@"Yesterday", @"Yesterday");
    }
    else {
        return NSLocalizedString(@"Today", @"Today");
    }
}

@end