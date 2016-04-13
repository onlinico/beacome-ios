//
// Created by Oleksandr Malyarenko on 1/18/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import "PBLabel.h"


@implementation PBLabel {

}


- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.numberOfLines == 0 && self.preferredMaxLayoutWidth != CGRectGetWidth(self.frame)) {
        self.preferredMaxLayoutWidth = self.frame.size.width;
        [self setNeedsUpdateConstraints];
    }
}


- (CGSize)intrinsicContentSize {
    CGSize s = [super intrinsicContentSize];

    if (self.numberOfLines == 0) {
        // found out that sometimes intrinsicContentSize is 1pt too short!
        s.height += 1;
    }

    return s;
}

@end