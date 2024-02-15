//
//  ViewController.m
//  Example-ObjC
//
//  Created by Abhijeet Mallick on 14/02/24.
//

#import "ViewController.h"
#import "Example_ObjC-Swift.h"
#import "Device.pbobjc.h"
#import "App.pbobjc.h"
#import "User.pbobjc.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)trackEventToClickstream:(UIButton *)sender {
    NSLog(@"trackEventToClickstream");
    AnalyticsManager *analyticsManager = [AnalyticsManager new] ;
    [analyticsManager initialiseClickstream];
    NSDictionary *dict = @{ @"Authorization" : @"Basic ", @"X-UniqueId" : [[UIDevice currentDevice] identifierForVendor].UUIDString};
    
    NSString *guid = [[NSUUID UUID]UUIDString];
    NSDate *currentDate = [NSDate date];
    
    
    
    Device *device = [Device new];
    device.operatingSystem = @"iOS";
    device.operatingSystemVersion = [[UIDevice currentDevice] systemVersion];
    device.deviceMake = @"Apple";
    device.deviceModel = @"iPhone 13 Pro";
    
    App *app = [App new];
    app.version = @"1.0.0";
    app.packageName = @"com.clickstream.app";
    
    User *user = [User new];
    user.guid = guid;
    user.name = @"Harry Potter";
    user.age = 20;
    user.gender = @"Male";
    user.phoneNumber = 0000000000;
    user.email = @"harry.potter@hogwarts.com";
    user.device = device;
    user.app = app;
}

- (IBAction)showEventVisualiser:(UIButton *)sender {
    NSLog(@"this feature is not available for ObjC");
}

@end
