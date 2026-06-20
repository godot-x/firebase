#import "godotx_apn_delegate.h"
#import "godotx_firebase_messaging_internal.h"
#include "godotx_firebase_messaging.h"

@import Firebase;

@implementation GodotxAPNDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"[GodotxAPNDelegate] Initialized");
    }
    return self;
}

- (void)activateNotificationCenterDelegate {
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    NSLog(@"[GodotxAPNDelegate] UNUserNotificationCenter delegate activated");
}

+ (instancetype)shared {
    static GodotxAPNDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GodotxAPNDelegate alloc] init];
    });
    return sharedInstance;
}

// Note: reserved keys filtering and recursive parsing is now handled centrally 
// in GodotxFirebaseMessaging::user_info_to_dictionary

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {

    NSDictionary *userInfo = notification.request.content.userInfo;
    [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
    NSLog(@"[GodotxAPNDelegate] Received notification in foreground: %@", userInfo);
    self.lastNotificationInfo = userInfo;

    NSString *title = notification.request.content.title ?: @"";
    NSString *body = notification.request.content.body ?: @"";
    Dictionary data = user_info_to_dictionary(userInfo);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->emit_signal("messaging_message_received",
                String::utf8([title UTF8String]),
                String::utf8([body UTF8String]),
                data);
        }
    });

    completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {

    NSDictionary *userInfo = response.notification.request.content.userInfo;
    [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
    NSLog(@"[GodotxAPNDelegate] User tapped notification: %@", userInfo);
    self.lastNotificationInfo = userInfo;

    NSString *title = response.notification.request.content.title ?: @"";
    NSString *body = response.notification.request.content.body ?: @"";
    Dictionary data = user_info_to_dictionary(userInfo);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->emit_signal("messaging_message_received",
                String::utf8([title UTF8String]),
                String::utf8([body UTF8String]),
                data);
        }
    });

    completionHandler();
}

@end
