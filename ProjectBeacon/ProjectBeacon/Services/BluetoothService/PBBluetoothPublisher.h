//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBBluetoothDelegate.h"


@interface PBBluetoothPublisher : NSObject


@property (nonatomic, assign) id <PBBluetoothDelegate> delegate;
@property (nonatomic, strong, readonly) NSUUID *advertisenmentUUID;
@property (nonatomic, assign, readonly) NSInteger advertisenmentMajor;
@property (nonatomic, assign, readonly) NSInteger advertisenmentMinor;
@property (nonatomic, assign, readonly) NSInteger devicePower;

- (void)setupPublisher;
- (void)startAdvertising;

- (void)stopAdvertising;

- (BOOL)publisherStatus;

@end