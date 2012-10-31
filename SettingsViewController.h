//
//  SettingsViewController.h
//  Viewer
//
//  Created by Jonathan Turpin on 24/10/12.
//
//

#import <UIKit/UIKit.h>
#import "PEPinEntryController.h"

@interface SettingsViewController : UIViewController <PEPinEntryControllerDelegate>
{
	int mypin;
    UIWindow *_window;
    UINavigationBar *navigationBar;
    IBOutlet UILabel *label;
    IBOutlet UIButton *bChangePin;
}

- (IBAction)changePin;
- (IBAction)cancelSettings;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic,retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic,retain) IBOutlet UILabel *label;
@property (nonatomic,retain) IBOutlet UIButton *bChangePin;

@end
