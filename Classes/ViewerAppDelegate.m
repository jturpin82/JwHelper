//
//	ViewerAppDelegate.m
//	Viewer v1.0.0
//
//	Created by Julius Oklamcak on 2012-09-01.
//	Copyright © 2011-2012 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ReaderConstants.h"
#import "ViewerAppDelegate.h"
#import "LibraryViewController.h"
#import "DirectoryWatcher.h"
#import "CoreDataManager.h"
#import "DocumentsUpdate.h"
#import "DocumentFolder.h"

#import "ASIHTTPRequest.h"
#import "TSMiniWebBrowser.h"
#import "SettingsViewController.h"
#import "UserInfos.h"

#include <sys/xattr.h>

@interface ViewerAppDelegate () <DirectoryWatcherDelegate>

@end

@implementation ViewerAppDelegate 
{
	LibraryViewController *rootViewController;
	DirectoryWatcher *directoryWatcher;
	NSTimer *directoryWatcherTimer;
}

#pragma mark Miscellaneous methods

- (void)registerAppDefaults
{
	NSNumber *hideStatusBar = [NSNumber numberWithBool:YES];

	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];

	NSString *version = [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey];

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults]; // User defaults

	NSDictionary *defaults = [NSDictionary dictionaryWithObject:hideStatusBar forKey:kReaderSettingsHideStatusBar];

	[userDefaults registerDefaults:defaults]; [userDefaults synchronize]; // Save user defaults

	[userDefaults setObject:version forKey:kReaderSettingsAppVersion]; // App version
}

- (void)prePopulateCoreData
{
	NSManagedObjectContext *mainMOC = [[CoreDataManager sharedInstance] mainManagedObjectContext];

	if ([DocumentFolder existsInMOC:mainMOC type:DocumentFolderTypeDefault] == NO) // Add default folder
	{
		NSString *folderName = NSLocalizedString(@"Documents", @""); // Localized default folder name

		[DocumentFolder insertInMOC:mainMOC name:folderName type:DocumentFolderTypeDefault]; // Insert it
	}

	if ([DocumentFolder existsInMOC:mainMOC type:DocumentFolderTypeRecent] == NO) // Add recent folder
	{
		NSString *folderName = NSLocalizedString(@"Recent", @""); // Localized recent folder name

		[DocumentFolder insertInMOC:mainMOC name:folderName type:DocumentFolderTypeRecent]; // Insert it
	}
}

#pragma mark UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    NSLog(@"handleOpenURL");
	return [[DocumentsUpdate sharedInstance] handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    //Encrypt Documents folder (if not already done)
    NSError *error;
    NSString *documentsPath = [DocumentsUpdate documentsPath]; // Application Documents path

    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSDictionary *attrs = [fm attributesOfItemAtPath:documentsPath error:&error];
  
    //Si le répertoire n'est pas encore encodé
    if(![[attrs objectForKey:NSFileProtectionKey] isEqual:NSFileProtectionComplete]) {
        BOOL success = [fm setAttributes:attrs ofItemAtPath:documentsPath error:&error];
        if (!success) {
               NSLog(@"%@ encryption NOT successfull!",documentsPath);
        }
        else {
            NSLog(@"%@ encryption successfull.",documentsPath);
        }
    }
    else {
        NSLog(@"%@ encryption already done,.",documentsPath);
    }
    
    
    
    //Register notifications
    #if !TARGET_IPHONE_SIMULATOR
        [application registerForRemoteNotificationTypes:
        UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    #endif
    
	application.applicationIconBadgeNumber = 0;
    
    TSMiniWebBrowser *webBrowser = [[TSMiniWebBrowser alloc] initWithUrl:[NSURL URLWithString:@"https://www.jw.org"]];
    //webBrowser.delegate = self;
	
    webBrowser.mode = TSMiniWebBrowserModeTabBar;
    webBrowser.barStyle = UIBarStyleBlackTranslucent;
	[self.navigationController pushViewController:webBrowser animated:YES];
	webBrowser.title = NSLocalizedString(@"Browser", nil);
	webBrowser.tabBarItem.image = [UIImage imageNamed:@"globe.png"];
	
	//On récupère le story board
	//UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil];
	
    
	//On initialise un tabBarController
	self.tabBarController = [[UITabBarController alloc] init];
	//[[self window] setRootViewController:tabBarController];
  
    
	//UIViewController *settingsView = [storyboard instantiateViewControllerWithIdentifier:@"SettingsView"];
	UIViewController *settingsView = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    settingsView.tabBarItem.image = [UIImage imageNamed:@"cog_02.png"];
    settingsView.title = NSLocalizedString(@"Parameters", nil);
    
	[self registerAppDefaults]; // Register various application settings defaults
	[self prePopulateCoreData]; // Pre-populate Core Data store with various default objects

	if ((launchOptions != nil) && ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey] != nil))
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kReaderSettingsCurrentDocument]; // Clear
	}

	u_int8_t value = 1; // Value for iCloud and iTunes 'do not backup' item setxattr() function

	setxattr([documentsPath fileSystemRepresentation], "com.apple.MobileBackup", &value, 1, 0, 0);

	if ([[UIDevice currentDevice].systemVersion floatValue] >= 5.0f) // Only if iOS 5.0 and newer
	{
		directoryWatcher = [DirectoryWatcher watchFolderWithPath:documentsPath delegate:self];
	}

    UIViewController *documentsViewController = [[LibraryViewController alloc] initWithNibName:nil bundle:nil];
	documentsViewController.tabBarItem.image = [UIImage imageNamed:@"safe.png"];
	documentsViewController.title = NSLocalizedString(@"Documents", nil);
	
	//on ajoute les éléments aux onglets
	self.tabBarController.viewControllers = [NSArray arrayWithObjects:webBrowser, documentsViewController,settingsView, nil];
    self.window.rootViewController = self.tabBarController; // Set the root view controller
    
    //Test du PIN
    [self testPin];
    
	return YES;
}


- (void)testPin {
    //On vérifie si l'utilisateur a défini un mot de passe
    NSManagedObjectContext *mainMOC = [[CoreDataManager sharedInstance] mainManagedObjectContext];
    if(![UserInfos existsInMOC:mainMOC]){
        NSLog(@"No Pincode set");
        //[self.tabBarController setSelectedIndex:2];
        
        PEPinEntryController *c = [PEPinEntryController pinCreateController];
        c.pinDelegate = self;
        c.title = NSLocalizedString(@"MustDefinePassword",@"");
        [self.window addSubview:c.view];
        [self.window makeKeyAndVisible];
        [self.window.rootViewController presentViewController:c animated:NO completion:nil];
    }
    else {
        //Documents par défaut
        [self verifyPin];
        //[self.tabBarController setSelectedIndex:1];
    }
}


- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of
	// temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application
	// and it begins the transition to the background state. Use this method to pause ongoing tasks, disable timers,
	// and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

	[[NSUserDefaults standardUserDefaults] synchronize]; // Save user defaults
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough
	// application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //Test du PIN
    [self testPin];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive.
	// If the application was previously in the background, optionally refresh the user interface.

	[[DocumentsUpdate sharedInstance] queueDocumentsUpdate]; // Queue a documents update
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate.
	// See also applicationDidEnterBackground:.

	[[NSUserDefaults standardUserDefaults] synchronize]; // Save user defaults
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	// Free up as much memory as possible by purging cached data objects that can be recreated
	// (or reloaded from disk) later.

	NSLog(@"%s", __FUNCTION__);
}

#pragma mark ViewerAppDelegate instance methods

- (void)dealloc
{
	[directoryWatcherTimer invalidate];
}

#pragma mark DirectoryWatcherDelegate methods

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
    //NSLog(@"Changement de répertoire");
    [self.tabBarController setSelectedIndex:1];
    
	if (directoryWatcherTimer != nil) { [directoryWatcherTimer invalidate]; directoryWatcherTimer = nil; } // Invalidate and release previous timer
	directoryWatcherTimer = [NSTimer scheduledTimerWithTimeInterval:1.2 target:self selector:@selector(watcherTimerFired:) userInfo:nil repeats:NO];
}

- (void)watcherTimerFired:(NSTimer *)timer
{
	[directoryWatcherTimer invalidate]; directoryWatcherTimer = nil; // Invalidate and release timer

	[[DocumentsUpdate sharedInstance] queueDocumentsUpdate]; // Queue a documents update
}



- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	application.applicationIconBadgeNumber = 0;
    
	// We can determine whether an application is launched as a result of the user tapping the action
	// button or whether the notification was delivered to the already-running application by examining
	// the application state.
	
	if (application.applicationState == UIApplicationStateActive) {
		// Nothing to do if applicationState is Inactive, the iOS already displayed an alert view.
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"JW Notification"
															message:[NSString stringWithFormat:@"%@",
																	 [[userInfo objectForKey:@"aps"] objectForKey:@"alert"]]
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
		[alertView show];
	}
}


#pragma mark -
#pragma mark Remote notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	// Send device token to the server by asynchronous http call
	NSString* deviceTokenString = [[[[deviceToken description]
                                      stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                     stringByReplacingOccurrencesOfString: @">" withString: @""]
                                    stringByReplacingOccurrencesOfString: @" " withString: @""];
	
	NSString *preferredLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
	NSLog(@"%@",preferredLanguage);
    
	NSString *urlString = [NSString stringWithFormat:@"http://joe.carvino.com/JwHelper/registerToken.php?token=%@&lang=%@", deviceTokenString, preferredLanguage];
	//NSLog(@"URL String : %@", urlString);
	
	NSURL *url = [NSURL URLWithString:urlString];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setDelegate:self];
	[request startAsynchronous];
	
	NSLog(@"Did register for remote notifications: %@", deviceToken);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Fail to register for remote notifications: %@", error);
}

#pragma mark -
#pragma mark Memory management





- (void)requestFinished:(ASIHTTPRequest *)request
{
	// Use when fetching text data
	//NSString *responseString = [request responseString];
	
	// Use when fetching binary data
	//NSData *responseData = [request responseData];
	
	/*
     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"JW Notification"
     message:[NSString stringWithFormat:@"Réponse:\n%@",responseString]
     delegate:self
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
     [alertView show];
	 */
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	//NSError *error = [request error];
}


#pragma mark -
#pragma mark PIN Mangement

- (IBAction)newPin
{
	PEPinEntryController *c = [PEPinEntryController pinCreateController];

    c.pinDelegate = self;
    [self.window addSubview:c.view];
    [self.window makeKeyAndVisible];
    [self.window.rootViewController presentViewController:c animated:NO completion:nil];
}

- (IBAction)changePin
{
	PEPinEntryController *c = [PEPinEntryController pinChangeController];
	c.pinDelegate = self;
    [self.window addSubview:c.view];
    [self.window makeKeyAndVisible];
    [self.window.rootViewController presentViewController:c animated:NO completion:nil];
}

- (IBAction)verifyPin
{
	PEPinEntryController *c = [PEPinEntryController pinVerifyController];
    c.pinDelegate = self;
    [self.window addSubview:c.view];
    [self.window makeKeyAndVisible];
    [self.window.rootViewController presentViewController:c animated:NO completion:nil];
}

- (BOOL)pinEntryController:(PEPinEntryController *)c shouldAcceptPin:(NSUInteger)pin
{
    NSLog(@"ViewerAppDelegate - shouldAcceptPin");
    
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
	//NSLog(@"viewerAppDelegate - New pin is set to %d", pin);
	[self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    
    //Persistence en BDD
    NSManagedObjectContext *mainMOC = [[CoreDataManager sharedInstance] mainManagedObjectContext];
    
    NSString *pinString = [NSString stringWithFormat:@"%d", pin];
    
    [UserInfos insertInMOC:mainMOC pincode:pinString];
    
    [self.tabBarController setSelectedIndex:1];
    
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
    [self.tabBarController setSelectedIndex:1];    
	[self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];

}


@end
