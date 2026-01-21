#ifndef GODOTX_APN_DELEGATE_H
#define GODOTX_APN_DELEGATE_H

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@interface GodotxAPNDelegate : NSObject <UNUserNotificationCenterDelegate>

+ (instancetype)shared;
- (void)activateNotificationCenterDelegate;

@end

#endif // GODOTX_APN_DELEGATE_H

