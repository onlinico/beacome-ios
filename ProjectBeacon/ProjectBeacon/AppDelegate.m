//
//  AppDelegate.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 11/16/15.
//  Copyright © 2015 Onlinico. All rights reserved.
//

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <TwitterKit/TwitterKit.h>
#import <Fabric/Fabric.h>
#import <Google/SignIn.h>
#import "AppDelegate.h"
#import "PBApplicationFacade.h"
#import "PBIntroViewController.h"
#import "PBSignInViewController.h"
#import "Constants.h"
#import "PBError.h"
#import "PBMainViewController.h"
#import <CocoaLumberjack/CocoaLumberjack.h>


static NSString *const kTwitterKey = @"FuAflXM4r05ODoNoUDEkkFcGy";
static NSString *const kTwitterSecret = @"hCYUB7eYhKg0P9431mPRy4RfH7cqcQ3lqqF0Q0UKbzrWKyJW63";


static NSString *const URLScheme = @"beacome";


@interface AppDelegate () {
    UIBackgroundTaskIdentifier _backgroundTask;
    Boolean _inBackground;
}


@property (nonatomic, strong) NSString *cardShareGuid;
@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init]; // File Logger
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:fileLogger];
    DDLogVerbose(@"Verbose");
    DDLogDebug(@"Debug");
    DDLogInfo(@"Info");
    DDLogWarn(@"Warn");
    DDLogError(@"Error");


    _backgroundTask = UIBackgroundTaskInvalid;
    _inBackground = YES;


    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    [[Twitter sharedInstance] startWithConsumerKey:kTwitterKey consumerSecret:kTwitterSecret];
    [Fabric with:@[[Twitter sharedInstance]]];
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    DDLogError(@"%@", configureError);


    [self instantiateRootController];
    return YES;
}


- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options {
    if ([[url scheme] isEqualToString:URLScheme]) {
        NSDictionary *parameters = [self parseQueryString:[url query]];
        self.cardShareGuid = parameters[@"uuid"];
        self.needsToProcessURLSchemeRequest = YES;

        [self instantiateRootController];
        return YES;
    }
    return [[FBSDKApplicationDelegate sharedInstance] application:app openURL:url sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey] annotation:options[UIApplicationOpenURLOptionsAnnotationKey]] || [[GIDSignIn sharedInstance] handleURL:url sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey] annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[url scheme] isEqualToString:URLScheme]) {
        NSDictionary *parameters = [self parseQueryString:[url query]];
        self.cardShareGuid = parameters[@"uuid"];
        self.needsToProcessURLSchemeRequest = YES;

        [self instantiateRootController];
        return YES;
    }
    return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation] || [[GIDSignIn sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self extendBackgroundRunningTime];
    _inBackground = YES;
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSDKAppEvents activateApp];
    _inBackground = NO;
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)extendBackgroundRunningTime {
    NSLog(@"background task extend");
    if (_backgroundTask != UIBackgroundTaskInvalid) {
        return;
    }

    __block Boolean self_terminate = YES;
    _backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"MonitoringBackgroundTask" expirationHandler:^{
        if (self_terminate) {
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
            _backgroundTask = UIBackgroundTaskInvalid;
        }
    }];
}


- (void)processURLSchemeRequest {
    [[PBApplicationFacade sharedManager] acceptCardSharing:self.cardShareGuid callback:^(BOOL result){
        if(!result){
            NSError *error = [NSError errorWithDomain:kPBErrorDomain code:kPBServiceErrorCantAcceptShareCardCode userInfo:@{NSLocalizedDescriptionKey : [PBError localizedDescriptionForKey:kPBServiceErrorCantAcceptShareCard]}];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        }
    }];
}


- (void)instantiateRootController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([[PBApplicationFacade sharedManager] isFirstLaunch]) {
        PBIntroViewController *introViewController = (PBIntroViewController *) [storyboard instantiateInitialViewController];
        self.window.rootViewController = introViewController;
        [self.window makeKeyAndVisible];
    }
    else if ([[PBApplicationFacade sharedManager] needsLogin]) {
        PBSignInViewController *signInViewController = (PBSignInViewController *) [storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
        self.window.rootViewController = signInViewController;
        [self.window makeKeyAndVisible];
    }
    else {
        PBMainViewController *tabBarController = (PBMainViewController *) [storyboard instantiateViewControllerWithIdentifier:@"TabBarController"];
        self.window.rootViewController = tabBarController;
        [self.window makeKeyAndVisible];
    }
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary] ;
    NSArray *pairs = [query componentsSeparatedByString:@"&"];

    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [elements[0] stringByRemovingPercentEncoding];
        NSString *val = [elements[1] stringByRemovingPercentEncoding];

        dict[key] = val;
    }
    return dict;
}

@end
