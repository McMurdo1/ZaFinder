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

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UIActionSheetDelegate>
{
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    NSMutableArray *topFourResults;
    __weak IBOutlet UITableView *pizzaTableView;

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
    segmentedControl.frame = CGRectMake(20, 80, 280, 50);
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(methodChosen:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segmentedControl];
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pizzaLocationReuseIdentifier"];
    

    
    
    NSLog(@"Ordered Search Results are %@", topFourResults);
    
    PizzaMapItem *tempPizza = [topFourResults objectAtIndex:indexPath.row];
    cell.textLabel.text = tempPizza.mapItemProperty.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%f", tempPizza.distance];
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
    request.source = [MKMapItem mapItemForCurrentLocation];
    for (PizzaMapItem *item in topFourResults)
    {
        request.destination = item.mapItemProperty;
        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error)
        {
            if (error)
            {
                NSLog(@"The ETA could not be returned");
            }
            else
            {
                if ((long)[segmentedControl selectedSegmentIndex] == 0)
                {
                    request.transportType = MKDirectionsTransportTypeWalking;
                }
                if ((long)[segmentedControl selectedSegmentIndex] == 1) {
                    request.transportType = MKDirectionsTransportTypeAutomobile;
                }
            }
        }]
        
    }
    
    NSLog(@"sender is %ld", (long)[segmentedControl selectedSegmentIndex]);
    
}




@end
