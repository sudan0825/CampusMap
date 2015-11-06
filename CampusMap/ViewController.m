//
//  ViewController.m
//  CampusMap
//
//  Created by Dan Su on 10/31/15.
//  Copyright © 2015 Dan Su. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

@import GoogleMaps;


@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIImageView*  imageView;
@property(strong, nonatomic) IBOutlet UIScrollView* scrollView;
@property (nonatomic, readonly) CLLocationCoordinate2D northEast;
@property (nonatomic, readonly) CLLocationCoordinate2D southWest;
@property (nonatomic, retain) CLLocationManager *locationManager;

@property GMSPlacesClient* placesClient;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@end

@implementation ViewController
{
    GMSMapView *googleMapView_;
    GMSPlacesClient *_placesClient;
    BOOL firstLocationUpdate_;
   
   
    NSMutableArray *totalString;
    NSMutableArray *filteredString;
    BOOL isFilltered;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _placesClient =[[GMSPlacesClient alloc] init];
    // Do any additional setup after loading the view, typically from a nib.
   
 

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadView {
    //enable location manager for authorization
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestAlwaysAuthorization];
  
 //define loaded google map
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:37.335728
                                                          longitude:-121.881566
                                                            zoom:16];
    
    googleMapView_=[GMSMapView mapWithFrame:CGRectZero camera:camera];
    
     self.view=googleMapView_;
    
    //get my location
    googleMapView_.settings.compassButton =YES;
    googleMapView_.settings.myLocationButton=YES;
    
    //Listen to the myLocation property of GMSMapView.
    [googleMapView_ addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew context:NULL];
    
    
    
    
    //Ask for my location data after map is loaded
    dispatch_async(dispatch_get_main_queue(), ^{
        googleMapView_.myLocationEnabled=YES;});
    
     NSLog(@"User's location: %@", googleMapView_.myLocation);
    
  
    //create a search bar with 600 width and 400 height
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,20, 500, 44)];
    
    _searchBar.delegate=self;
    //add search bar to googlemapview
    [googleMapView_ addSubview:_searchBar ];
    //change cursor color
    _searchBar.tintColor=[UIColor blueColor];
    
    _searchBar.searchBarStyle=UISearchBarStyleDefault;
    //enable searchbar be editable
    _searchBar.becomeFirstResponder;
   //add table view to search result(did not finish)
    _tableView.delegate=self;
    
    [googleMapView_ addSubview:_tableView];
 
    //tap screen to zoom in and out
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    
    //load mapImage
  
    UIImage *mapImage = [UIImage imageNamed:@"campusmap.jpg"];
   
    _imageView = [[UIImageView alloc] initWithImage:mapImage];
  //init scrollview and add imageview to it
    _scrollView = [[UIScrollView alloc] initWithFrame:_imageView.frame];
    _scrollView.contentSize = CGSizeMake(_imageView.frame.size.width, _imageView.frame.size.height);
    //enable gesture recognizeer
    [_scrollView addGestureRecognizer:tapGesture];
    
    [_scrollView addSubview:_imageView];
    //enable user interaction
    _scrollView.userInteractionEnabled = YES;
    //picture zoom in and out scale
    _scrollView.maximumZoomScale = 5;
    _scrollView.minimumZoomScale = 1;
    _scrollView.bounces = NO;
    _scrollView.bouncesZoom = NO;
    _scrollView.delegate = self;
 
    // define the center of map image
  CLLocationCoordinate2D center=CLLocationCoordinate2DMake(37.335725, -121.881570);
  //define the overlay center
    GMSGroundOverlay *overlay =
    [GMSGroundOverlay groundOverlayWithPosition:center
                                           icon:mapImage
                                      zoomLevel:16.7];
     //overlay picture to google map
     overlay.map = googleMapView_;
    //adjust the position of image
    overlay.bearing=-31;
  //enable picture
    
    overlay.tappable = YES;
    
    
    //define marker
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(37.335725, -121.881561);
    marker.title = @"San Jose State University";
    marker.snippet = @"CA, USA";
    marker.map = googleMapView_;
    
    CLLocationCoordinate2D position1 = CLLocationCoordinate2DMake(37.335565, -121.885084);
    GMSMarker *lib = [GMSMarker markerWithPosition:position1];
    lib.title = @"King Library";
    lib.snippet = @"Dr. Martin Luther King, Jr. Library, 150 East San Fernando Street, San Jose, CA 95112";
    lib.infoWindowAnchor = CGPointMake(0.5, 0.5);
    lib.icon = [UIImage imageNamed:@"wht_pushpin"];
    lib.opacity=0;
    lib.map = googleMapView_;
    
    CLLocationCoordinate2D position2 = CLLocationCoordinate2DMake(37.337250, -121.881399);
    GMSMarker *eng = [GMSMarker markerWithPosition:position2];
    eng.title = @"Engineering Building";
    eng.snippet = @"San José State University Charles W. Davidson College of Engineering, 1 Washington Square, San Jose, CA 95112";
    eng.infoWindowAnchor = CGPointMake(0.5, 0.5);
    eng.icon = [UIImage imageNamed:@"wht_pushpin"];
    eng.opacity=0;
    eng.map = googleMapView_;
    
    CLLocationCoordinate2D position3 = CLLocationCoordinate2DMake(37.336650, -121.878613);
    GMSMarker *bbc = [GMSMarker markerWithPosition:position3];
    bbc.title = @"BBC";
    bbc.snippet = @"Boccardo Business Complex, San Jose, CA 95112";
    bbc.infoWindowAnchor = CGPointMake(0.5, 0.5);
    bbc.icon = [UIImage imageNamed:@"wht_pushpin"];
    bbc.opacity=0;
    bbc.map = googleMapView_;

    CLLocationCoordinate2D position4 = CLLocationCoordinate2DMake(37.333531, -121.883775);
    GMSMarker *YUH = [GMSMarker markerWithPosition:position4];
    YUH.title = @"Yoshihiro Uchida Hall";
    YUH.snippet = @"Yoshihiro Uchida Hall, San Jose, CA 95112";
    YUH.infoWindowAnchor = CGPointMake(0.5, 0.5);
    YUH.icon = [UIImage imageNamed:@"wht_pushpin"];
    YUH.opacity=0;
    YUH.map = googleMapView_;
    
    CLLocationCoordinate2D position5 = CLLocationCoordinate2DMake(37.336308, -121.881362);
    GMSMarker *SU = [GMSMarker markerWithPosition:position5];
    SU.title = @"Student Union";
    SU.snippet = @"Student Union Building, San Jose, CA 95112";
    SU.infoWindowAnchor = CGPointMake(0.5, 0.5);
    SU.icon = [UIImage imageNamed:@"wht_pushpin"];
    SU.opacity=0;
    SU.map = googleMapView_;
    
    CLLocationCoordinate2D position6 = CLLocationCoordinate2DMake(37.333003, -121.880842);
    GMSMarker *garage = [GMSMarker markerWithPosition:position6];
    garage.title = @"South Parking Garage";
    garage.snippet = @"San Jose State University South Garage, 330 South 7th Street, San Jose, CA 95112";
    garage.infoWindowAnchor = CGPointMake(0.5, 0.5);
    garage.icon = [UIImage imageNamed:@"wht_pushpin"];
    garage.opacity=0;
    garage.map = googleMapView_;
   
    
    
}
// dealloc my location

- (void)dealloc {
    [googleMapView_ removeObserver:self
                  forKeyPath:@"myLocation"
                     context:NULL];
}

#pragma mark - KVO updates

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (!firstLocationUpdate_) {
        // If the first location update has not yet been recieved, then jump to that
        // location.
        firstLocationUpdate_ = YES;
        CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
        googleMapView_.camera = [GMSCameraPosition cameraWithTarget:location.coordinate
                                                         zoom:16];
    }
}

//detect tap
-(void)tapDetected:(UIGestureRecognizer*)recognizer{
    NSLog(@"tap detected.");
    CGPoint point = [recognizer locationInView:self.imageView];
    
    NSLog(@"x = %f y = %f", point.x, point.y );
}
//return zoom in screen
-(UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [[self.view subviews] objectAtIndex:0];
}
//enable search bar function (did not finish)
-(void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
   if(searchText.length==0)
   {
       isFilltered=NO;
   }
    else
    {
        isFilltered=YES;
        filteredString=[[NSMutableArray alloc]init];
        CLGeocoder *coder=[[CLGeocoder alloc]init];
        NSString *address=searchText;
        [coder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error){
        
        }];
        
    }

}

//enble address auto completion (did not work)
- (void)placeAutocomplete {
    
    GMSVisibleRegion visibleRegion = self->googleMapView_.projection.visibleRegion;
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:visibleRegion.farLeft
                                                                       coordinate:visibleRegion.nearRight];
    GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];
    filter.type = kGMSPlacesAutocompleteTypeFilterCity;
    
    [_placesClient autocompleteQuery:@"San Jose State University"
                              bounds:bounds
                              filter:filter
                            callback:^(NSArray *results, NSError *error) {
                                if (error != nil) {
                                    NSLog(@"Autocomplete error %@", [error localizedDescription]);
                                    return;
                                }
                                
                                for (GMSAutocompletePrediction* result in results) {
                                    NSLog(@"Result '%@' with placeID %@", result.attributedFullText.string, result.placeID);
                                }
                            }];
}

@end
