//
// Created by Oleksandr Malyarenko on 12/30/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <Foundation/Foundation.h>


static NSString *const kPBErrorDomain = @"PBErrorDomain";

static NSInteger const kPBBluetoothErrorMonitoringNotAvailableCode = 10100;
static NSInteger const kPBBluetoothErrorRangingNotAvailableCode = 10101;
static NSInteger const kPBBluetoothErrorPublishingNotSupportedCode = 10102;
static NSInteger const kPBBluetoothErrorBluetoothIsOffCode = 10103;
static NSInteger const kPBBluetoothErrorBluetoothIsNotAuthorizedCode = 10104;
static NSInteger const kPBBluetoothErrorBluetoothIsResettingCode = 10105;
static NSInteger const kPBBluetoothErrorUnknownCode = 10106;

static NSInteger const kPBImagePickerErrorNotImageTypeCode = 20100;

static NSInteger const kPBServiceErrorCantShareCardCode = 30100;
static NSInteger const kPBServiceErrorCantImportVCardCode = 30101;
static NSInteger const kPBServiceErrorCantAcceptShareCardCode = 30102;

static NSInteger const kPBUIErrorUUIDIsNotValidCode = 40100;
static NSInteger const kPBUIErrorDataIsNotValidCode = 40101;
static NSInteger const kPBUIErrorCantSignOutCode = 40102;
static NSInteger const kPBUIErrorCantConnectSocialNetworkCode = 40103;

static NSInteger const kPBWebserviceErrorCode = 50100;
static NSInteger const kPBWebserviceConnectionErrorCode = 50101;
static NSInteger const kPBWebserviceBeaconLinkBusyErrorCode = 50102;

static NSString *const kPBBluetoothErrorMonitoringNotAvailable = @"Bluetooth monitoring is not available for this device";
static NSString *const kPBBluetoothErrorRangingNotAvailable = @"Ranging is disabled. This might happen if the device is in Airplane mode or if Bluetooth or location services are disabled.";
static NSString *const kPBBluetoothErrorPublishingNotSupported = @"Bluetooth low energy is not supported by this device";
static NSString *const kPBBluetoothErrorBluetoothIsOff = @"Bluetooth module is off";
static NSString *const kPBBluetoothErrorBluetoothIsNotAuthorized = @"Application is not authorized to use the Bluetooth low energy";
static NSString *const kPBBluetoothErrorBluetoothIsResetting = @"The connection with the system service was momentarily lost";
static NSString *const kPBBluetoothErrorUnknown = @"Bluetooth is not available for this device";


static NSString *const kPBImagePickerErrorNotImageType = @"Selected media is not an image type";

static NSString *const kPBServiceErrorCantShareCard = @"Can't share card right now";
static NSString *const kPBServiceErrorCantImportVCard = @"Can't import vcard right now";
static NSString *const kPBServiceErrorCantAcceptShareCard = @"Can't accept card sharing right now";

static NSString *const kPBUIErrorUUIDIsNotValid = @"Entered UUID is not valid";
static NSString *const kPBUIErrorDataIsNotValid = @"Some fields are not filled or entered data is not valid";
static NSString *const kPBUIErrorCantSignOut = @"Application can't sign out now because of problems with web service";
static NSString *const kPBUIErrorCantConnectSocialNetwork = @"Can't connect social network. It may be problem with web service or this social network account already linked to another user.";

static NSString *const kPBWebserviceError = @"An error of the web service. Please try again later.";
static NSString *const kPBWebserviceConnectionError = @"The Internet connection appears to be offline.";
static NSString *const kPBWebserviceBeaconLinkBusyError = @"You don't have access to Beacon that you want to link.";


@interface PBError : NSObject 

+ (NSString *)localizedDescriptionForKey:(NSString *)key;
+ (NSError *)checkAndCreateInApplicationError:(NSError *)externalError;

@end