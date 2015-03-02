#import "AAPLViewController.h"
#import "AAPLCoordinateConverter.h"

@interface AAPLViewController () <CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *pinView;
@property (weak, nonatomic) IBOutlet UIImageView *first_floor_layout;
@property (weak, nonatomic) IBOutlet UIImageView *second_floor_layout;
@property (nonatomic, weak) IBOutlet UIImageView *radiusView;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) AAPLCoordinateConverter *coordinateConverter;

@property CGFloat displayScale;
@property CGPoint displayOffset;

@property (nonatomic) AAPLGeoAnchorPair anchorPair;

@end

@implementation AAPLViewController

@synthesize segmentedControl;

- (void)viewDidLoad {
	[super viewDidLoad];

	// Setup a reference to location manager.
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.locationManager.activityType = CLActivityTypeFitness;

	// We setup a pair of anchors that will define how the floorplan image, maps to geographic co-ordinates
    AAPLGeoAnchor anchor1 = {
        .latitudeLongitude = CLLocationCoordinate2DMake(44.859926, -93.456424),
        .pixel = CGPointMake(384, 1157)
    };

    AAPLGeoAnchor anchor2 = {
        .latitudeLongitude = CLLocationCoordinate2DMake(44.859566, -93.454110),
        .pixel = CGPointMake(1919, 1468)
    };

    self.anchorPair = (AAPLGeoAnchorPair) {
        .fromAnchor = anchor1,
        .toAnchor = anchor2
    };

	// Initialize the coordinate system converter with two anchor points.
	self.coordinateConverter = [[AAPLCoordinateConverter alloc] initWithAnchors:self.anchorPair];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:false];
    [self setScaleAndOffset];
    [self startTrackingLocation];
}

- (void) setScaleAndOffset {
    
    CGSize imageViewFrameSize = self.first_floor_layout.frame.size;
    CGSize imageSize = self.first_floor_layout.image.size;

    // Calculate how much we'll be scaling the image to fit on screen.
    self.displayScale = MIN(imageViewFrameSize.width / imageSize.width, imageViewFrameSize.height / imageSize.height);
    NSLog(@"Scale Factor: %f", self.displayScale);

    // Depending on whether we're constrained by width or height,
    // figure out how much our floorplan pixels need to be offset to adjust for the image being centered
    if (imageViewFrameSize.width / imageSize.width < imageViewFrameSize.height / imageSize.height) {
        NSLog(@"Constrained by width");
        self.displayOffset = CGPointMake(0, (imageViewFrameSize.height - imageSize.height * self.displayScale) / 2);
    } else {
        NSLog(@"Constrained by height");
        self.displayOffset = CGPointMake((imageViewFrameSize.width - imageSize.width * self.displayScale) / 2, 0);
    }

    NSLog(@"Offset: %f, %f", self.displayOffset.x, self.displayOffset.y);
}

- (void)startTrackingLocation {
	CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
		[self.locationManager requestWhenInUseAuthorization];
    }
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
		[self.locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	switch (status) {
		case kCLAuthorizationStatusAuthorizedAlways:
		case kCLAuthorizationStatusAuthorizedWhenInUse:
			NSLog(@"Got authorization, start tracking location");
			[self startTrackingLocation];
            break;
		case kCLAuthorizationStatusNotDetermined:
			[self.locationManager requestWhenInUseAuthorization];
		default:
			break;
	}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // Pass location updates to the map view.
	[locations enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
        NSLog(@"Location (Floor %@): %@", location.floor, location.description);
		[self updateViewWithLocation:location];
	}];
}

- (void) updateViewWithLocation: (CLLocation *) location {
	// We animate transition from one position to the next, this makes the dot move smoothly over the map
	[UIView animateWithDuration:0.75 animations:^ {
		// Call the converter to find these coordinates on our floorplan.
		CGPoint pointOnImage = [self.coordinateConverter pointFromCoordinate:location.coordinate];

		// These coordinates need to be scaled based on how much the image has been scaled
		CGPoint scaledPoint = CGPointMake(pointOnImage.x * self.displayScale + self.displayOffset.x,
										  pointOnImage.y * self.displayScale + self.displayOffset.y);

		// Calculate and set the size of the radius
		CGFloat radiusFrameSize = location.horizontalAccuracy * self.coordinateConverter.pixelsPerMeter * 0.01;
		self.radiusView.frame = CGRectMake(0, 0, radiusFrameSize, radiusFrameSize);

		// Move the pin and radius to the user's location
		self.pinView.center = scaledPoint;
		self.radiusView.center = scaledPoint;
	}];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self setScaleAndOffset];
}

- (IBAction)segmentedControlAction:(id)sender {
    // Checking which segment is selected using the segment index value
    if(segmentedControl.selectedSegmentIndex == 0)
        
    {
        self.first_floor_layout.alpha = 1;
        self.second_floor_layout.alpha = 0;
    }
    
    else
        
        if(segmentedControl.selectedSegmentIndex == 1)
        {
            self.first_floor_layout.alpha = 0;
            self.second_floor_layout.alpha = 1;   
        }

}

@end
