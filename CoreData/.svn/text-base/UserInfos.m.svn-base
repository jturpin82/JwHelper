//
//  UserInfos.m
//  JwHelper
//
//  Created by Jonathan Turpin on 29/10/12.
//
//

#import "UserInfos.h"


@implementation UserInfos

#pragma mark Constants

#define kUserInfos @"UserInfos"

#pragma mark Properties

@dynamic pincode;

#pragma mark UserInfos Core Data class methods


+ (UserInfos *)getFromMOC:(NSManagedObjectContext *)inMOC
{
	assert(inMOC != nil); // Check parameter
    
	NSFetchRequest *request = [NSFetchRequest new]; // Fetch request instance
    
	[request setEntity:[NSEntityDescription entityForName:kUserInfos inManagedObjectContext:inMOC]];
    
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"pincode" ascending:YES];
    
	[request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]]; // Sort order
    
	//[request setReturnsObjectsAsFaults:NO]; [request setFetchBatchSize:24]; // Optimize fetch

	__autoreleasing NSError *error = nil; // Error information object
    
    NSArray *objectList = [inMOC executeFetchRequest:request error:&error];
    
	UserInfos *object = [objectList objectAtIndex:0];
    
	if (object == nil) { NSLog(@"%s %@", __FUNCTION__, error); assert(NO); }
    
	return object;
}


+ (BOOL)existsInMOC:(NSManagedObjectContext *)inMOC
{
	assert(inMOC != nil); // Check parameter
    
	NSFetchRequest *request = [NSFetchRequest new]; // Fetch request instance
    
	[request setEntity:[NSEntityDescription entityForName:kUserInfos inManagedObjectContext:inMOC]];
    
	__autoreleasing NSError *error = nil; // Error information object
    
	NSUInteger count = [inMOC countForFetchRequest:request error:&error];
    
	if (error != nil) { NSLog(@"%s %@", __FUNCTION__, error); assert(NO); }
    
	return ((count > 0) ? YES : NO);
}


+ (UserInfos *)insertInMOC:(NSManagedObjectContext *)inMOC pincode:(NSString *)pin
{
	assert(inMOC != nil); assert(pin != nil); // Check parameters
    
	UserInfos *object = [NSEntityDescription insertNewObjectForEntityForName:kUserInfos inManagedObjectContext:inMOC];
    
	if ((object != nil) && ([object isMemberOfClass:[UserInfos class]])) // Valid UserInfos object
	{
		object.pincode = pin;
        
		__autoreleasing NSError *error = nil; // Error information object
        
		if ([inMOC hasChanges] == YES) // Save changes
		{
			if ([inMOC save:&error] == NO) // Did save changes
			{
				NSLog(@"%s %@", __FUNCTION__, error); assert(NO);
			}
		}
	}
    
	return object;
}


+ (void)deleteInMOC:(NSManagedObjectContext *)inMOC object:(UserInfos *)object
{
	assert(inMOC != nil); assert(object != nil); // Check parameters
	[inMOC deleteObject:object]; // Delete the object
}

@end
