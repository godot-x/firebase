#import "drivers/apple_embedded/godot_app_delegate.h"
#include "godotx_firebase_messaging.h"
#import "godotx_firebase_messaging_internal.h"

@import Firebase;

@implementation GDTApplicationDelegate (APNS)

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"[GodotxFirebaseMessaging] didRegisterForRemoteNotificationsWithDeviceToken");

    [FIRMessaging messaging].APNSToken = deviceToken;

    const unsigned char *data = (const unsigned char *)deviceToken.bytes;
    NSMutableString *token = [NSMutableString string];
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }

    NSLog(@"[GodotxFirebaseMessaging] APNs Token: %@", token);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->emit_signal(
                "messaging_apn_token_received",
                String([token UTF8String])
            );
        }
    });
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"[GodotxFirebaseMessaging] Failed to register for remote notifications: %@", error.localizedDescription);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->emit_signal(
                "messaging_error",
                String::utf8([error.localizedDescription UTF8String])
            );
        }
    });
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[FIRMessaging messaging] appDidReceiveMessage:userInfo]; 
    NSLog(@"[GodotxFirebaseMessaging] didReceiveRemoteNotification (Silent/Background): %@", userInfo);

    // If it's a silent push (content-available: 1), it won't trigger UNUserNotificationCenterDelegate.
    // We emit the signal here directly.
    
    // Extract title/body if present (usually empty in silent push)
    NSString *title = @"";
    NSString *body = @"";
    NSDictionary *aps = userInfo[@"aps"];
    if ([aps isKindOfClass:[NSDictionary class]]) {
        id alert = aps[@"alert"];
        if ([alert isKindOfClass:[NSDictionary class]]) {
            title = alert[@"title"] ?: @"";
            body = alert[@"body"] ?: @"";
        } else if ([alert isKindOfClass:[NSString class]]) {
            body = alert;
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->emit_signal(
                "messaging_message_received",
                String::utf8([title UTF8String]),
                String::utf8([body UTF8String]),
                user_info_to_dictionary(userInfo)
            );
        }
    });

    completionHandler(UIBackgroundFetchResultNewData);
}

@end
