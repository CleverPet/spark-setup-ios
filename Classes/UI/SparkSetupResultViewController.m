//
//  SparkSetupSuccessFailureViewController.m
//  teacup-ios-app
//
//  Created by Ido on 2/3/15.
//  Copyright (c) 2015 spark. All rights reserved.
//

#import "SparkSetupResultViewController.h"
#import "SparkSetupUIElements.h"
#import "SparkSetupMainController.h"
#import "SparkSetupWebViewController.h"
#import "SparkSetupCustomization.h"
#ifdef FRAMEWORK
#import <ParticleSDK/ParticleSDK.h>
#else
#import "Spark-SDK.h"
#endif
#ifdef ANALYTICS
#import <SEGAnalytics.h>
#endif

//#import "CPPet.h"
//#import "CPUserManager.h"

@interface SparkSetupResultViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet SparkSetupUILabel *shortMessageLabel;
@property (weak, nonatomic) IBOutlet SparkSetupUILabel *longMessageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *setupResultImageView;
@property (weak, nonatomic) IBOutlet UIImageView *brandImageView;

@property (weak, nonatomic) IBOutlet SparkSetupUILabel *nameDeviceLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameDeviceTextField;
@property (strong, nonatomic) NSArray *randomDeviceNamesArray;
@property (weak, nonatomic) IBOutlet SparkSetupUIButton *troubleshootingButton;
@property (nonatomic) BOOL deviceNamed;
@end

@implementation SparkSetupResultViewController


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ([SparkSetupCustomization sharedInstance].lightStatusAndNavBar) ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // set logo
    self.brandImageView.image = [SparkSetupCustomization sharedInstance].brandImage;
    self.brandImageView.backgroundColor = [SparkSetupCustomization sharedInstance].brandImageBackgroundColor;
    
    self.nameDeviceLabel.hidden = YES;
    self.nameDeviceTextField.hidden = YES;

    // Trick to add an inset from the left of the text fields
    CGRect  viewRect = CGRectMake(0, 0, 10, 32);
    UIView* emptyView = [[UIView alloc] initWithFrame:viewRect];
    
    self.nameDeviceTextField.leftView = emptyView;
    self.nameDeviceTextField.leftViewMode = UITextFieldViewModeAlways;
    self.nameDeviceTextField.delegate = self;
    self.nameDeviceTextField.returnKeyType = UIReturnKeyDone;
    self.nameDeviceTextField.font = [UIFont fontWithName:[SparkSetupCustomization sharedInstance].normalTextFontName size:16.0];

    // init funny random device names
    self.randomDeviceNamesArray = [NSArray arrayWithObjects:@"aardvark", @"bacon", @"badger", @"banjo", @"bobcat", @"boomer", @"captain", @"chicken", @"cowboy", @"maker", @"splendid", @"sparkling", @"dentist", @"doctor", @"green", @"easter", @"ferret", @"gerbil", @"hacker", @"hamster", @"wizard", @"hobbit", @"hoosier", @"hunter", @"jester", @"jetpack", @"kitty", @"laser", @"lawyer", @"mighty", @"monkey", @"morphing", @"mutant", @"narwhal", @"ninja", @"normal", @"penguin", @"pirate", @"pizza", @"plumber", @"power", @"puppy", @"ranger", @"raptor", @"robot", @"scraper", @"burrito", @"station", @"tasty", @"trochee", @"turkey", @"turtle", @"vampire", @"wombat", @"zombie", nil];
    
    self.deviceNamed = NO;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewDidAppear:(BOOL)animated
{
    if ((!isiPhone4) && (!isiPhone5))
        [self disableKeyboardMovesViewUp];
    
    if (self.setupResult == SparkSetupMainControllerResultSuccess)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.nameDeviceTextField becomeFirstResponder];
        });
    }
}

-(void)viewWillAppear:(BOOL)animated
{
#ifdef ANALYTICS
    [[SEGAnalytics sharedAnalytics] track:@"Device Setup: Setup Result Screen"];
#endif

    
    [super viewWillAppear:animated];
    
    switch (self.setupResult) {
        case SparkSetupMainControllerResultSuccess:
        {
            self.setupResultImageView.image = [SparkSetupMainController loadImageFromResourceBundle:@"success"];
            self.shortMessageLabel.text = @"Setup completed successfully";
            self.longMessageLabel.text = @"Congrats! You've successfully set up your {device}.";
            self.troubleshootingButton.hidden = YES;
            /* Device naming now automatic.
            self.nameDeviceLabel.hidden = NO;
            self.nameDeviceTextField.hidden = NO;
            NSString *randomDeviceName1 = self.randomDeviceNamesArray[arc4random_uniform((UInt32)self.randomDeviceNamesArray.count)];
            NSString *randomDeviceName2 = self.randomDeviceNamesArray[arc4random_uniform((UInt32)self.randomDeviceNamesArray.count)];
            self.nameDeviceTextField.text = [NSString stringWithFormat:@"%@_%@",randomDeviceName1,randomDeviceName2];
            */
            
            //CPPet *thisPet = [[CPUserManager sharedInstance] getCurrentUser].pet;
            
            //TODO: Should be modifying the Pod via it's own fork (not locally)
            
            /* 
             Also modified for autocomplete:
             "Done" button set to hidden in IB
             nameDeviceTextField user interaction disabled in IB
            */
            
            NSString *defaultDeviceName = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultDeviceName"];
            
            if (defaultDeviceName != nil) {
                self.nameDeviceTextField.text = defaultDeviceName;
                
            } else {
                //Current flow forces pet to be setup before device.
                //So we should always have a validated default device name.
                NSAssert(NO, @"Pet name should be stored already.");
            }
            
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"Device Setup: Success"];
#endif

            //////////
            //TODO: Launch Spinner?
            
            //Wait 2 sec
            [self performSelector:@selector(doAutocomplete) withObject:nil afterDelay:2.0];
            
            break;
        }
            
        case SparkSetupMainControllerResultSuccessDeviceOffline:
        {
            self.setupResultImageView.image = [SparkSetupMainController loadImageFromResourceBundle:@"failure"];
            self.shortMessageLabel.text = @"Error!";
            self.longMessageLabel.text = @"Your Hub couldn’t connect to WiFi. Is the WiFi signal where you put the Hub strong enough? Did you enter your WiFi password correctly?\n\nTo try setup again: a) remove the Hub dome b) unplug the Hub and plug it back in c) touch the center touchpad three times and d) place the dome back on the Hub base. When the light on the Hub dome flashes blue, press Continue.\n\nStill having trouble?";
            
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"Device Setup: Success" properties:@{@"reason":@"device offline"}];
#endif
            break;
        }

        case SparkSetupMainControllerResultSuccessNotClaimed:
        {
            self.setupResultImageView.image = [SparkSetupMainController loadImageFromResourceBundle:@"failure"];
            self.shortMessageLabel.text = @"Error!";
            self.longMessageLabel.text = @"Your Hub couldn’t connect to WiFi. Is the WiFi signal where you put the Hub strong enough? Did you enter your WiFi password correctly?\n\nTo try setup again: a) remove the Hub dome b) unplug the Hub and plug it back in c) touch the center touchpad three times and d) place the dome back on the Hub base. When the light on the Hub dome flashes blue, press Continue.\n\nStill having trouble?";
            
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"Device Setup: Success" properties:@{@"reason":@"not claimed"}];
#endif
            break;
            
        }
            
        case SparkSetupMainControllerResultFailureClaiming:
        {
            self.setupResultImageView.image = [SparkSetupMainController loadImageFromResourceBundle:@"failure"];
            self.shortMessageLabel.text = @"Error!";
            // TODO: add customization point for custom troubleshoot texts
//            self.longMessageLabel.text = @"Setup process failed at claiming your {device}, if your {device} LED is blinking in blue or green this means that you provided wrong Wi-Fi credentials. If {device} LED is breathing cyan an internal cloud issue occured - please contact product support.";
            self.longMessageLabel.text = @"Your Hub couldn’t connect to WiFi. Is the WiFi signal where you put the Hub strong enough? Did you enter your WiFi password correctly?\n\nTo try setup again: a) remove the Hub dome b) unplug the Hub and plug it back in c) touch the center touchpad three times and d) place the dome back on the Hub base. When the light on the Hub dome flashes blue, press Continue.\n\nStill having trouble?";
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"Device Setup: Failure" properties:@{@"reason":@"claiming failed"}];
#endif

            break;
        }
            
        case SparkSetupMainControllerResultFailureCannotDisconnectFromDevice:
        {
            self.setupResultImageView.image = [SparkSetupMainController loadImageFromResourceBundle:@"failure"];
            self.shortMessageLabel.text = @"Error!";
            self.longMessageLabel.text = @"Your Hub couldn’t connect to WiFi. Is the WiFi signal where you put the Hub strong enough? Did you enter your WiFi password correctly?\n\nTo try setup again: a) remove the Hub dome b) unplug the Hub and plug it back in c) touch the center touchpad three times and d) place the dome back on the Hub base. When the light on the Hub dome flashes blue, press Continue.\n\nStill having trouble?";
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"Device Setup: Failure" properties:@{@"reason":@"cannot disconnect"}];
#endif

            break;
        }
            
  
        case SparkSetupMainControllerResultFailureConfigure:
        {
            self.setupResultImageView.image = [SparkSetupMainController loadImageFromResourceBundle:@"failure"];
            self.shortMessageLabel.text = @"Error!";
            self.longMessageLabel.text = @"Your Hub couldn’t connect to WiFi. Is the WiFi signal where you put the Hub strong enough? Did you enter your WiFi password correctly?\n\nTo try setup again: a) remove the Hub dome b) unplug the Hub and plug it back in c) touch the center touchpad three times and d) place the dome back on the Hub base. When the light on the Hub dome flashes blue, press Continue.\n\nStill having trouble?";
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"Device Setup: Failure" properties:@{@"reason":@"cannot configure"}];
#endif
            break;
        }
            
        default: //SparkSetupMainControllerResultFailureLostConnectionToDevice
        {
            self.setupResultImageView.image = [SparkSetupMainController loadImageFromResourceBundle:@"failure"];
            self.shortMessageLabel.text = @"Error!";
            self.longMessageLabel.text = @"Your Hub couldn’t connect to WiFi. Is the WiFi signal where you put the Hub strong enough? Did you enter your WiFi password correctly?\n\nTo try setup again: a) remove the Hub dome b) unplug the Hub and plug it back in c) touch the center touchpad three times and d) place the dome back on the Hub base. When the light on the Hub dome flashes blue, press Continue.\n\nStill having trouble?";
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"Device Setup: Failure" properties:@{@"reason":@"lost connection"}];
#endif
            
            break;
        }
            
            
    }
    
    [self.longMessageLabel setType:@"normal"];

    /*
    if ([SparkSetupCustomization sharedInstance].tintSetupImages)
    {
        self.setupResultImageView.image = [self.setupResultImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.setupResultImageView.tintColor = [SparkSetupCustomization sharedInstance].normalTextColor;// elementBackgroundColor;;
    }
     */

}

//Completing the setup process w/o user entering device name.
-(void)doAutocomplete{
    [self.device rename:self.nameDeviceTextField.text completion:^(NSError *error) {
        [self doneButtonTapped:self];
    }];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    if (textField == self.nameDeviceTextField)
    {
        [self.device rename:self.nameDeviceTextField.text completion:^(NSError *error) {
            if (error) {
                NSLog(@"Rrror naming device %@",error.description);
            } else {
                self.deviceNamed = YES;
            }
            [textField resignFirstResponder];
            [self doneButtonTapped:self];
        }];
        
    }
    
    return YES;
    
}


- (IBAction)doneButtonTapped:(id)sender
{
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    if (self.device)
        userInfo[kSparkSetupDidFinishDeviceKey] = self.device;

    if (self.deviceID)
        userInfo[kSparkSetupDidFailDeviceIDKey] = self.deviceID;

    userInfo[kSparkSetupDidFinishStateKey] = @(self.setupResult);
    
    if (self.setupResult == SparkSetupMainControllerResultSuccess)
    {
        // Update zero notice to user
        // TODO: condition message only if its really getting update zero (need event listening)
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"shownUpdateZeroNotice"]) {
            // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Firmware update" message:@"If this is the first time you are setting up this device it might blink its LED in magenta color for a while, this means the device is currently updating its firmware from the cloud to the latest version. Please be patient and do not press the reset button. Device LED will breathe cyan once update has completed and it has come online." delegate:nil cancelButtonTitle:@"Understood" otherButtonTitles:nil];
            // [alert show];
     
        if (!self.deviceNamed) {
            [self.device rename:self.nameDeviceTextField.text completion:^(NSError *error) {
                if (error) {
                    NSLog(@"error name device %@",error.description);
                } else {
                    self.deviceNamed = YES;
                }
            }];
        }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shownUpdateZeroNotice"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    // finish with success and provide device
    [[NSNotificationCenter defaultCenter] postNotificationName:kSparkSetupDidFinishNotification
                                                        object:nil
                                                      userInfo:userInfo];

}


- (IBAction)troubleshootingButtonTouched:(id)sender
{
    SparkSetupWebViewController* webVC = [[UIStoryboard storyboardWithName:@"setup" bundle:[NSBundle bundleWithIdentifier:SPARK_SETUP_RESOURCE_BUNDLE_IDENTIFIER]] instantiateViewControllerWithIdentifier:@"webview"];
    webVC.link = [SparkSetupCustomization sharedInstance].troubleshootingLinkURL;
    [self presentViewController:webVC animated:YES completion:nil];
}
- (IBAction)cleverpetTroubleshootingButtonPressed:(id)sender {
    NSURL *actionURL = [[NSURL alloc] initWithString:@"http://support.clever.pet/connecting-to-wifi"];
    [[UIApplication sharedApplication] openURL:actionURL];
}



@end
