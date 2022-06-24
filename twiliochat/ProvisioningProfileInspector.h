//
//  ProvisioningProfileInspector.h
//  twiliochat
//
//  Created by Vikram Adityan on 17/6/2022.
//  Copyright © 2022 Twilio. All rights reserved.
//

#ifndef ProvisioningProfileInspector_h
#define ProvisioningProfileInspector_h

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSUInteger, APNSEnvironment)
{
    APNSEnvironmentUnknown,
    APNSEnvironmentDevelopment,
    APNSEnvironmentProduction
};

@interface ProvisioningProfileInspector : NSObject

- (NSDictionary *)dictionary;

- (APNSEnvironment)APNSEnvironment;

@end

#endif /* ProvisioningProfileInspector_h */
