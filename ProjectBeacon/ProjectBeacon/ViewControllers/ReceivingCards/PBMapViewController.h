//
//  PBMapViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 2/10/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface PBMapViewController : UIViewController
@property (weak, nonatomic) IBOutlet MKMapView *map;

@property (nonatomic, strong) NSString *cardTitle;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double distance;

@end
