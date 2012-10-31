//
//  PinEntryViewController.m
//  PinEntry
//
//  Created by Farcaller on 21.10.10.
//  Copyright 2010 Codeneedle. All rights reserved.
//

#import "PinEntryViewController.h"
#import "UserInfos.h"
#import "CoreDataManager.h"

@implementation PinEntryViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if( (self = [super initWithCoder:aDecoder]) ) {
		mypin = 1234;
	}
	return self;
}

- (IBAction)newPin
{
	PEPinEntryController *c = [PEPinEntryController pinCreateController];
	c.pinDelegate = self;
	[self presentViewController:c animated:YES completion:nil];
}

- (IBAction)changePin
{
	PEPinEntryController *c = [PEPinEntryController pinChangeController];
	c.pinDelegate = self;
	[self presentViewController:c animated:YES completion:nil];
}

- (IBAction)verifyPin
{
	PEPinEntryController *c = [PEPinEntryController pinVerifyController];
	c.pinDelegate = self;
	[self presentViewController:c animated:YES completion:nil];
}

- (BOOL)pinEntryController:(PEPinEntryController *)c shouldAcceptPin:(NSUInteger)pin
{
    NSLog(@"PinEntryViewController shouldAcceptPin");
    
    NSManagedObjectContext *mainMOC = [[CoreDataManager sharedInstance] mainManagedObjectContext];
    UserInfos *userInfos = [UserInfos getFromMOC:mainMOC];
    
    NSString *pinEntered = [NSString stringWithFormat:@"%d", pin];
    
	// Verify the pin, return NO if it's incorrect. Otherwise hide the controller and return YES
	if([pinEntered isEqualToString:userInfos.pincode]) {
		NSLog(@"Pin is valid!");
		if(c.verifyOnly == YES) {
			// Used for pinVerifyController, we should not hide pinChangeController yet
			[self dismissViewControllerAnimated:YES completion:nil];
		}
		return YES;
	} else {
		//NSLog(@"Pin is not valid (use %d)!", mypin);
		return NO;
	}
}

- (void)pinEntryController:(PEPinEntryController *)c changedPin:(NSUInteger)pin
{
	// Update your info to new pin code
	mypin = pin;
	NSLog(@"New pin is set to %d", pin);
    
    NSManagedObjectContext *mainMOC = [[CoreDataManager sharedInstance] mainManagedObjectContext];
    
    NSString *pinString = [NSString stringWithFormat:@"%d", pin];
    
    [UserInfos insertInMOC:mainMOC pincode:pinString];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Mot de passe défini"
                                                        message:[NSString stringWithFormat:@"Merci de te connecter la prochaine fois avec ce mot de passe."]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pinEntryControllerDidCancel:(PEPinEntryController *)c
{
	NSLog(@"Pin change cancelled!");
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
