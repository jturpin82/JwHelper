//
//  UserInfos.h
//  JwHelper
//
//  Created by Jonathan Turpin on 29/10/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UserInfos : NSManagedObject

@property (nonatomic) NSString *pincode;

+ (UserInfos *)insertInMOC:(NSManagedObjectContext *)inMOC pincode:(NSString *)pin;
+ (UserInfos *)getFromMOC:(NSManagedObjectContext *)inMOC;
+ (BOOL)existsInMOC:(NSManagedObjectContext *)inMOC;
+ (void)deleteInMOC:(NSManagedObjectContext *)inMOC object:(UserInfos *)object;

@end
