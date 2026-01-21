#import "godotx_apn_delegate.h"
#include "godotx_firebase_messaging.h"

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

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {

    NSDictionary *userInfo = notification.request.content.userInfo;
    NSLog(@"[GodotxAPNDelegate] Received notification in foreground: %@", userInfo);

    NSString *title = notification.request.content.title ?: @"";
    NSString *body = notification.request.content.body ?: @"";

    dispatch_async(dispatch_get_main_queue(), ^{
        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->emit_signal("messaging_message_received",
                String([title UTF8String]),
                String([body UTF8String]));
        }
    });

    if (@available(iOS 14.0, *)) {
        completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
    } else {
        completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {

    NSDictionary *userInfo = response.notification.request.content.userInfo;
    NSLog(@"[GodotxAPNDelegate] User tapped notification: %@", userInfo);

    NSString *title = response.notification.request.content.title ?: @"";
    NSString *body = response.notification.request.content.body ?: @"";

    dispatch_async(dispatch_get_main_queue(), ^{
        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->emit_signal("messaging_message_received",
                String([title UTF8String]),
                String([body UTF8String]));
        }
    });

    completionHandler();
}

@end

