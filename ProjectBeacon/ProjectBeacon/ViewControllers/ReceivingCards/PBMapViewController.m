//
//  PBMapViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 2/10/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBMapViewController.h"

@interface PBMapViewController () <MKMapViewDelegate>

@end

@implementation PBMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.map.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude];
    MKCircle *circleOverlay = [MKCircle circleWithCenterCoordinate:location.coordinate radius:self.distance];
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = location.coordinate;
    point.title = self.cardTitle;
    [self.map addOverlay:circleOverlay];
    [self.map addAnnotation:point];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - MapView delegate methods

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKMapRect mapRect = MKMapRectNull;

    //annotations is an array with all the annotations I want to display on the map
    for (id<MKAnnotation> annotation in self.map.annotations) {

        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);

        if (MKMapRectIsNull(mapRect))
        {
            mapRect = pointRect;
        } else
        {
            mapRect = MKMapRectUnion(mapRect, pointRect);
        }
    }

    [self.map setVisibleMapRect:mapRect edgePadding:UIEdgeInsetsMake(30,30,30,30) animated:YES];
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{

    if ([overlay isKindOfClass:[MKCircle class]])
    {
        MKCircleRenderer* aRenderer = [[MKCircleRenderer alloc] initWithCircle:(MKCircle *)overlay];

        aRenderer.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
        aRenderer.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
        aRenderer.lineWidth = 1;
        return aRenderer;
    }else{
        return nil;
    }
}

@end
