#import "drivers/apple_embedded/godot_app_delegate.h"
#include "godotx_firebase_messaging.h"

@import Firebase;

@implementation GDTApplicationDelegate (APNS)

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"[GodotxFirebaseMessaging] didRegisterForRemoteNotificationsWithDeviceToken");

    if (![FIRApp defaultApp]) {
        NSLog(@"[GodotxFirebaseMessaging] Firebase not configured yet, skipping APNs token");
        return;
    }

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
                String([error.localizedDescription UTF8String])
            );
        }
    });
}

@end
