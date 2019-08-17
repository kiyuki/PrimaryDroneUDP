//
//  DefaultLayoutViewController.m
//  UILibraryDemo
//
//  Created by DJI on 16/4/2017.
//  Copyright © 2017 DJI. All rights reserved.
//

#import "DefaultLayoutViewController.h"
// #import "UXSDKDemo-Swift.h"
@import SocketIO;

@interface DefaultLayoutViewController ()<DJISDKManagerDelegate, DJIFlightControllerDelegate>
//@property SocSwi* socSwi;
@property NSURL* url;
@property SocketManager* manager;
@property SocketIOClient* socket;
@property int socketNum;
@property NSMutableDictionary* fPosiBuff;
@property NSMutableDictionary* socketSig;

@property DJIFlightController* flightController;
@property (atomic) CLLocation *PDLoc; // GPS info, lat, lon, alt
@property (atomic) DJIAttitude PDAtti; //pitch roll yaw
@property (atomic) float velX;
@property (atomic) float velY;
@property (atomic) float velZ;
@property (atomic) BOOL PDFlying;
@property (atomic) float PDAlt;
@property (atomic) float PDFlightTime;
@property (atomic) int gpsLevel;

@property Boolean virtualControlAvail;
@property Boolean motorFlag;

@property (weak, nonatomic) IBOutlet UILabel *Label1;
@property dispatch_semaphore_t semapho;
@end

@implementation DefaultLayoutViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [DJISDKManager registerAppWithDelegate:self];
    self.semapho = dispatch_semaphore_create(1);
    [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(Vmethod:) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(Tmethod:) userInfo:nil repeats:YES];
    self.url = [[NSURL alloc] initWithString:@"http://192.168.100.154:5000"];
    self.manager = [[SocketManager alloc] initWithSocketURL:self.url config:@{@"log": @YES, @"compress": @YES}];
    self.socket = self.manager.defaultSocket;
    self.socketNum = 0;
    
    self.PDLoc = [[CLLocation alloc] init];
    self.PDFlying = false;
    self.PDFlightTime = 0;
    
    [self.socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socket connected");
    }];
    [self.socket connect];
    self.fPosiBuff = [NSMutableDictionary dictionary];
    [self.fPosiBuff setObject:[NSNumber numberWithDouble:38.251455] forKey:@"lat"];
    [self.fPosiBuff setObject:[NSNumber numberWithDouble:140.875682] forKey:@"lon"];
    [self.fPosiBuff setObject:[NSNumber numberWithDouble:0.0] forKey:@"alt"];
    [self.fPosiBuff setObject:[NSNumber numberWithDouble:0.0] forKey:@"yaw"];
    [self.fPosiBuff setObject:[NSNumber numberWithDouble:0.0] forKey:@"pitch"];
    [self.fPosiBuff setObject:[NSNumber numberWithDouble:0.0] forKey:@"roll"];
    [self.fPosiBuff setObject:[NSNumber numberWithDouble:0.0] forKey:@"velX"];
    [self.fPosiBuff setObject:[NSNumber numberWithDouble:0.0] forKey:@"velY"];
    [self.fPosiBuff setObject:[NSNumber numberWithDouble:0.0] forKey:@"velZ"];
    self.socketSig = [NSMutableDictionary dictionary];
    [self.socketSig setObject:[NSNumber numberWithDouble:self.socketNum] forKey:@"PDSocketNum"];
}

- (void)showAlertViewWithMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* alertViewController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertViewController addAction:okAction];
        UIViewController *rootViewController = [[UIApplication sharedApplication] keyWindow].rootViewController;
        [rootViewController presentViewController:alertViewController animated:YES completion:nil];
    });

}

#pragma mark DJISDKManager Delegate Methods
- (void)appRegisteredWithError:(NSError *)error
{
    if (!error) {
        [self showAlertViewWithMessage:@"Registration Success"];
        [DJISDKManager startConnectionToProduct];
    }else
    {
        [self showAlertViewWithMessage:[NSString stringWithFormat:@"Registration Error:%@", error]];
    }
}

- (void)productConnected:(DJIBaseProduct *)product
{
    [[DJISDKManager userAccountManager] logIntoDJIUserAccountWithAuthorizationRequired:NO withCompletion:^(DJIUserAccountState state, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Login failed: %@", error.description);
        }
    }];
    self.flightController = [self fetchFlightController];
    self.flightController.delegate = self;
    ((DUXFPVViewController*)self.contentViewController).fpvView.showCameraDisplayName = false;
}


- (void) flightController:(DJIFlightController *)fc didUpdateState:(DJIFlightControllerState *)state{
    self.PDLoc = state.aircraftLocation;
    self.PDAtti = state.attitude;
    self.PDFlying = state.isFlying;
    self.PDAlt = state.altitude;
    self.PDFlightTime = state.flightTimeInSeconds;
    self.gpsLevel = state.GPSSignalLevel;
    self.velX = state.velocityX;
    self.velY = state.velocityY;
    self.velZ = state.velocityZ;
    // PDAtti contains pitch roll yaw. PDLoc is CLLocation which contains GPS info such lat, lon, alt
}

- (DJIFlightController*) fetchFlightController {
    if (![DJISDKManager product]) {
        return nil;
    }
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    return nil;
}

- (void)Vmethod:(NSTimer *)timer
{
    if(self.PDFlying){
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDLoc.coordinate.latitude] forKey:@"lat"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDLoc.coordinate.longitude] forKey:@"lon"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDAlt] forKey:@"alt"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDAtti.yaw] forKey:@"yaw"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDAtti.pitch] forKey:@"pitch"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDAtti.roll] forKey:@"roll"];
        [self.fPosiBuff setObject:[NSNumber numberWithFloat:self.PDFlightTime] forKey:@"flightTime"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.velX] forKey:@"velX"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.velY] forKey:@"velY"];
        [self.fPosiBuff setObject:[NSNumber numberWithFloat:self.velZ] forKey:@"velZ"];
        [self.socket emit:@"v1params" with:[NSArray arrayWithObject:self.fPosiBuff]];
    }else{
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDLoc.coordinate.latitude] forKey:@"lat"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDLoc.coordinate.longitude] forKey:@"lon"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDAlt] forKey:@"alt"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDAtti.yaw] forKey:@"yaw"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDAtti.pitch] forKey:@"pitch"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.PDAtti.roll] forKey:@"roll"];
        [self.fPosiBuff setObject:[NSNumber numberWithFloat:self.PDFlightTime] forKey:@"flightTime"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.velX] forKey:@"velX"];
        [self.fPosiBuff setObject:[NSNumber numberWithDouble:self.velY] forKey:@"velY"];
        [self.fPosiBuff setObject:[NSNumber numberWithFloat:self.velZ] forKey:@"velZ"];
        [self.socket emit:@"v1params" with:[NSArray arrayWithObject:self.fPosiBuff]];
    }
    self.Label1.text = [NSString stringWithFormat:@"%d, lat: %f, lon: %f, Alt: %f, yaw: %f", self.gpsLevel, self.PDLoc.coordinate.latitude,
                        self.PDLoc.coordinate.longitude, self.PDAlt, self.PDAtti.yaw];
}

- (void)Tmethod:(NSTimer *)timer{
    self.socketNum += 1;
    [self.socketSig setObject:[NSNumber numberWithFloat:self.socketNum] forKey:@"PDSocketNum"];
    [self.socket emit:@"pdSocket" with:[NSArray arrayWithObject:self.socketSig]];
}

@end
