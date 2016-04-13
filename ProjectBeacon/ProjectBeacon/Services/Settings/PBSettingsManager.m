//
// Created by Oleksandr Malyarenko on 12/2/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import "PBSettingsManager.h"


static NSString *const kFirstLaunch = @"FirstLaunch";
static NSString *const kLastSessionUserId = @"LastSessionUserId";
static NSString *const kLastSessionUserToken = @"LastSessionUserToken";
static NSString *const kLastSessionUserAuthProvider = @"LastSessionUserAuthProvider";
static NSString *const kDeviceAsBeaconUUID = @"DeviceAsBeaconUUID";
static NSString *const kBeaconIdentifier = @"BeaconIdentifier";
static NSString *const kIsPublisherEnabled = @"IsPublisherEnabled";
static NSString *const kIsWatcherEnabled = @"IsWatcherEnabled";
static NSString *const kDefaultBeaconIdentifier = @"com.onlinico.ProjectBeacon";


@interface PBSettingsManager ()


@property (nonatomic, strong) NSMutableDictionary *usersDeviceAsBeacon;

@end


@implementation PBSettingsManager {

}


#pragma mark Singleton Methods


+ (id)sharedManager {
    static PBSettingsManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}


- (instancetype)init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if ([defaults objectForKey:kDeviceAsBeaconUUID] != nil) {
            self.usersDeviceAsBeacon = [NSKeyedUnarchiver unarchiveObjectWithData:[defaults dataForKey:kDeviceAsBeaconUUID]];
        }
        else {
            self.usersDeviceAsBeacon = [NSMutableDictionary dictionary];
        }
        if ([defaults stringForKey:kBeaconIdentifier] != nil) {
            self.beaconIdentifier = [defaults stringForKey:kBeaconIdentifier];
        }
        else {
            self.beaconIdentifier = kDefaultBeaconIdentifier;
            [defaults setObject:self.beaconIdentifier forKey:kBeaconIdentifier];
        }
        _lastSessionUserId = [defaults integerForKey:kLastSessionUserId];
        _lastSessionUserToken = [defaults stringForKey:kLastSessionUserToken];
        _lastSessionUserAuthProvider = [defaults stringForKey:kLastSessionUserAuthProvider];
        self.isPublisherEnabled = [defaults boolForKey:kIsPublisherEnabled];
        self.isWatcherEnabled = [defaults boolForKey:kIsWatcherEnabled];
        _firstLaunch = ![defaults boolForKey:kFirstLaunch];
    }

    return self;
}


- (NSString *)deviceAsBeaconUUID {
    return self.usersDeviceAsBeacon[@(self.lastSessionUserId)];
}


- (void)setDeviceAsBeaconUUID:(NSString *)deviceAsBeaconUUID {
    self.usersDeviceAsBeacon[@(self.lastSessionUserId)] = deviceAsBeaconUUID;
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.usersDeviceAsBeacon] forKey:kDeviceAsBeaconUUID];
    [[NSUserDefaults standardUserDefaults] synchronize];

}


- (void)setLastSessionUserId:(NSInteger)lastSessionUserId {
    _lastSessionUserId = lastSessionUserId;
    [[NSUserDefaults standardUserDefaults] setObject:@(lastSessionUserId) forKey:kLastSessionUserId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setLastSessionUserToken:(NSString *)lastSessionUserToken {
    _lastSessionUserToken = lastSessionUserToken;
    [[NSUserDefaults standardUserDefaults] setObject:lastSessionUserToken forKey:kLastSessionUserToken];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setLastSessionUserAuthProvider:(NSString *)lastSessionUserAuthProvider {
    _lastSessionUserAuthProvider = lastSessionUserAuthProvider;
    [[NSUserDefaults standardUserDefaults] setObject:lastSessionUserAuthProvider forKey:kLastSessionUserAuthProvider];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setFirstLaunch:(BOOL)firstLaunch {
    _firstLaunch = !firstLaunch;
    [[NSUserDefaults standardUserDefaults] setBool:_firstLaunch forKey:kFirstLaunch];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setIsWatcherEnabled:(BOOL)isWatcherEnabled {
    _isWatcherEnabled = isWatcherEnabled;
    [[NSUserDefaults standardUserDefaults] setBool:_isWatcherEnabled forKey:kIsWatcherEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setIsPublisherEnabled:(BOOL)isPublisherEnabled {
    _isPublisherEnabled = isPublisherEnabled;
    [[NSUserDefaults standardUserDefaults] setBool:_isPublisherEnabled forKey:kIsPublisherEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end