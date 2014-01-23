//
//  ViewController.m
//  ZaFinder
//
//  Created by Matthew Graham on 1/22/14.
//  Copyright (c) 2014 Matthew Graham. All rights reserved.
//

#import "ViewController.h"
#import "CoreLocation/CoreLocation.h"
#import <MapKit/MapKit.h>
#import "PizzaMapItem.h"

extern double const EATINGTIME = 3000;

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UIActionSheetDelegate>
{
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    NSMutableArray *topFourResults;
    __weak IBOutlet UITableView *pizzaTableView;
    __weak IBOutlet UILabel *estimatedTimeLabel;

}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    topFourResults = [NSMutableArray new];
    
    NSArray *methodArray = [NSArray new];
    methodArray = [NSArray arrayWithObjects:@"Walking", @"TheStrikeMachine", nil];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:methodArray];
    segmentedControl.frame = CGRectMake(15, 80, 280, 40);
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(methodChosen:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segmentedControl];
    
    estimatedTimeLabel.alpha = 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pizzaLocationReuseIdentifier"];
    
    
    
    
    NSLog(@"Ordered Search Results are %@", topFourResults);
    
    PizzaMapItem *tempPizza = [topFourResults objectAtIndex:indexPath.row];
    cell.textLabel.text = tempPizza.mapItemProperty.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f meters", tempPizza.distance];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return topFourResults.count;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"The location manager failed with error: %@", error);
    UIActionSheet *sheet = [UIActionSheet new];
    sheet.title = @"Error";
    [sheet addButtonWithTitle:@"Please turn on location services"];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations)
    {
        if (location.verticalAccuracy > 1000 || location.horizontalAccuracy > 1000)
        {
            continue;
        }
        currentLocation = location;
        [locationManager stopUpdatingLocation];
        [self getPizzaLocations];
        
    }
}

-(void)getPizzaLocations
{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizza";
    MKCoordinateSpan span = MKCoordinateSpanMake(0.05, 0.05);
    request.region = MKCoordinateRegionMake(currentLocation.coordinate, span);
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
     {
         NSMutableArray *searchResults = [NSMutableArray new];
         for (MKMapItem *item in response.mapItems)
         {
             
             PizzaMapItem *pizzaPlace = [PizzaMapItem new];
             
             CLLocationDistance distance = [currentLocation distanceFromLocation:item.placemark.location];
             pizzaPlace.mapItemProperty = item;
             pizzaPlace.distance = distance;
             [searchResults addObject:pizzaPlace];
             
         }
         NSSortDescriptor *distanceSorter = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];
         [searchResults sortUsingDescriptors:[NSArray arrayWithObject:distanceSorter]];
         topFourResults = [searchResults subarrayWithRange:NSMakeRange(0, 4)];
         
         [pizzaTableView reloadData];
     }];
}


- (IBAction)methodChosen:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    
    if ((long)[segmentedControl selectedSegmentIndex] == 0)
    {
        request.transportType = MKDirectionsTransportTypeWalking;
    }
    if ((long)[segmentedControl selectedSegmentIndex] == 1) {
        request.transportType = MKDirectionsTransportTypeAutomobile;
    }
    __block double traveltime;

    
    MKMapItem *tempMapItem = [MKMapItem mapItemForCurrentLocation];
    int count = 0;
    for (PizzaMapItem *item in topFourResults)
    {
        count++;
        request.source = tempMapItem;
        request.destination = item.mapItemProperty;
        tempMapItem = item.mapItemProperty;
        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error)
         {
             if (error)
             {
                 NSLog(@"The ETA could not be returned");
                 estimatedTimeLabel.alpha = 1;
                 estimatedTimeLabel.text = @"Error";
             }
             else
             {
                 NSLog(@"%hhd", directions.calculating);
                 NSLog(@"response is %f",response.expectedTravelTime);
                 traveltime = traveltime + (double)response.expectedTravelTime;
                 NSLog(@"Travel time is %f", traveltime);
                 if (count == 4)
                 {
                     traveltime = traveltime + (EATINGTIME * (topFourResults.count - 1));
                     
                     estimatedTimeLabel.alpha = 1;
                     estimatedTimeLabel.text = [NSString stringWithFormat:@"%.1f mins",(traveltime / 60)];
                 }
             }
         }];
    }


}

- (IBAction)onMapButtonPressed:(id)sender
{
    [self performSegueWithIdentifier:@"MapViewSegue" sender:self.view];
}



@end
