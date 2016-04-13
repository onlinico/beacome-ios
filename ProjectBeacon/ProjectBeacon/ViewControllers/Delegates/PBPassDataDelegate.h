//
// Created by Oleksandr Malyarenko on 1/14/16.
// Copyright (c) 2016 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol PBPassDataDelegate <NSObject>


- (void)sender:(id)sender passData:(id)data;

@end