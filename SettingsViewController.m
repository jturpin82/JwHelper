//
//  SettingsViewController.m
//  Viewer
//
//  Created by Jonathan Turpin on 24/10/12.
//
//

#import "SettingsViewController.h"
#import "ViewerAppDelegate.h"
#import "CoreDataManager.h"
#import "UserInfos.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize label;
@synthesize navigationBar;
@synthesize bChangePin;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //self.title = NSLocalizedString(@"Parameters", @"");
    
    navigationBar.topItem.title = NSLocalizedString(@"Parameters",@"");
    
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *versionStr = [NSString stringWithFormat:@"JwHelper version %@",
                            [appInfo objectForKey:@"CFBundleVersion"]];
    //NSLog(@"Version : %@", versionStr);
    
    self.label.text = versionStr;
    self.bChangePin.titleLabel.text = NSLocalizedString(@"ChangePassword",@"");
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    //NSLog(@"width %f, height %f",screenBounds.size.width, screenBounds.size.height);
    
    CGRect frame = label.frame;
    
    if (screenBounds.size.height == 568) {
        // code for 4-inch screen (iPhone 5, iPod Touch 5g...)
        //NSLog(@"4-inch screen");
        frame.origin.y = 464;
        label.frame = frame;
    }
    else if(screenBounds.size.width >= 768) {
        //iPad et iPad Retina
        //NSLog(@"iPad (or iPad Retina)");
        frame.origin.y = 904;
        label.frame = frame;
        
        frame = bChangePin.frame;
        frame.origin.x = 280;
        bChangePin.frame = frame;
    }
}




- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    self.bChangePin.titleLabel.text = NSLocalizedString(@"ChangePassword",@"");
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
	if( (self = [super initWithCoder:aDecoder]) ) {
		mypin = 1234;
	}
	return self;
}


- (IBAction)changePin
{
    //self.bChangePin.titleLabel.text = NSLocalizedString(@"ChangePassword",@"");
	PEPinEntryController *c = [PEPinEntryController pinChangeController];
	c.pinDelegate = self;
	[self presentViewController:c animated:YES completion:nil];
}


- (BOOL)pinEntryController:(PEPinEntryController *)c shouldAcceptPin:(NSUInteger)pin
{
    //NSLog(@"SettingsViewController - shouldAcceptPin");
    
    NSManagedObjectContext *mainMOC = [[CoreDataManager sharedInstance] mainManagedObjectContext];
    UserInfos *userInfos = [UserInfos getFromMOC:mainMOC];
    
    NSString *pinEntered = [NSString stringWithFormat:@"%d", pin];
    
	// Verify the pin, return NO if it's incorrect. Otherwise hide the controller and return YES
	if([pinEntered isEqualToString:userInfos.pincode]) {
		NSLog(@"Pin is valid!");
		if(c.verifyOnly == YES) {
            [self.tabBarController setSelectedIndex:1];
            [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        }
        
		return YES;
	} else {
		//NSLog(@"Pin is not valid : %@ !", pinEntered);
		return NO;
	}
}

- (void)pinEntryController:(PEPinEntryController *)c changedPin:(NSUInteger)pin
{
	// Update your info to new pin code
	mypin = pin;
    
	//NSLog(@"New pin is set to %d", pin);
	[self dismissViewControllerAnimated:YES completion:nil];
    
    //Persistence en BDD
    NSManagedObjectContext *mainMOC = [[CoreDataManager sharedInstance] mainManagedObjectContext];
    
    NSString *pinString = [NSString stringWithFormat:@"%d", pin];
    
    UserInfos *userInfos = [UserInfos getFromMOC:mainMOC];
    [UserInfos deleteInMOC:mainMOC object:userInfos];
    
    [UserInfos insertInMOC:mainMOC pincode:pinString];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DefinedPassword",@"")
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"NextTimeWithPassword",@"")]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)pinEntryControllerDidCancel:(PEPinEntryController *)c
{
	NSLog(@"Pin change cancelled!");
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelSettings
{
    [self.tabBarController setSelectedIndex:1];
}

@end
