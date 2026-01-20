#import "godotx_firebase_messaging.h"
#import "godotx_apn_delegate.h"
#include "core/object/class_db.h"

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>

@import Firebase;

@interface GodotxFirebaseMessagingDelegate : NSObject <FIRMessagingDelegate>
@end

@implementation GodotxFirebaseMessagingDelegate

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    NSLog(@"[GodotxFirebaseMessaging] FCM registration token received: %@", fcmToken);

    if (!fcmToken || fcmToken.length == 0) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->emit_signal("messaging_token_received", String([fcmToken UTF8String]));
        }
    });
}

@end

GodotxFirebaseMessaging *GodotxFirebaseMessaging::instance = nullptr;
static GodotxFirebaseMessagingDelegate *messagingDelegate = nil;

void GodotxFirebaseMessaging::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize"), &GodotxFirebaseMessaging::initialize);
    ClassDB::bind_method(D_METHOD("request_permission"), &GodotxFirebaseMessaging::request_permission);
    ClassDB::bind_method(D_METHOD("get_token"), &GodotxFirebaseMessaging::get_token);
    ClassDB::bind_method(D_METHOD("get_apns_token"), &GodotxFirebaseMessaging::get_apns_token);
    ClassDB::bind_method(D_METHOD("subscribe_to_topic", "topic"), &GodotxFirebaseMessaging::subscribe_to_topic);
    ClassDB::bind_method(D_METHOD("unsubscribe_from_topic", "topic"), &GodotxFirebaseMessaging::unsubscribe_from_topic);

    ADD_SIGNAL(MethodInfo("messaging_permission_granted"));
    ADD_SIGNAL(MethodInfo("messaging_permission_denied"));
    ADD_SIGNAL(MethodInfo("messaging_token_received", PropertyInfo(Variant::STRING, "token")));
    ADD_SIGNAL(MethodInfo("messaging_apn_token_received", PropertyInfo(Variant::STRING, "token")));
    ADD_SIGNAL(MethodInfo("messaging_message_received", PropertyInfo(Variant::STRING, "title"), PropertyInfo(Variant::STRING, "body")));
    ADD_SIGNAL(MethodInfo("messaging_error", PropertyInfo(Variant::STRING, "message")));
}

GodotxFirebaseMessaging *GodotxFirebaseMessaging::get_singleton() {
    return instance;
}

GodotxFirebaseMessaging::GodotxFirebaseMessaging() {
    ERR_FAIL_COND(instance != nullptr);
    instance = this;
    NSLog(@"[GodotxFirebaseMessaging] Created");
}

GodotxFirebaseMessaging::~GodotxFirebaseMessaging() {
    if (instance == this) {
        instance = nullptr;
    }
}

void GodotxFirebaseMessaging::initialize() {
    NSLog(@"[GodotxFirebaseMessaging] Initializing...");

    if (![FIRApp defaultApp]) {
        NSLog(@"[GodotxFirebaseMessaging] Firebase core not ready");
        return;
    }

    if (messagingDelegate == nil) {
        [FIRMessaging messaging].autoInitEnabled = YES;
        messagingDelegate = [[GodotxFirebaseMessagingDelegate alloc] init];
        [FIRMessaging messaging].delegate = messagingDelegate;
        NSLog(@"[GodotxFirebaseMessaging] Messaging delegate configured");
    }

    [[GodotxAPNDelegate shared] activateNotificationCenterDelegate];

    NSLog(@"[GodotxFirebaseMessaging] Initialized");
}

void GodotxFirebaseMessaging::request_permission() {
    NSLog(@"[GodotxFirebaseMessaging] Requesting notification permission...");

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        UNAuthorizationStatus status = settings.authorizationStatus;

        if (status == UNAuthorizationStatusDenied) {
            NSLog(@"[GodotxFirebaseMessaging] Notification permission is denied");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (GodotxFirebaseMessaging::instance) {
                    GodotxFirebaseMessaging::instance->emit_signal("messaging_permission_denied");
                }
            });
            return;
        }

        if (status == UNAuthorizationStatusAuthorized ||
            status == UNAuthorizationStatusProvisional ||
            status == UNAuthorizationStatusEphemeral) {

            NSLog(@"[GodotxFirebaseMessaging] Notification already authorized");
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"[GodotxFirebaseMessaging] Calling registerForRemoteNotifications...");
                [[UIApplication sharedApplication] registerForRemoteNotifications];

                if (GodotxFirebaseMessaging::instance) {
                    GodotxFirebaseMessaging::instance->emit_signal("messaging_permission_granted");
                }
            });
            return;
        }

        UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert |
                                             UNAuthorizationOptionSound |
                                             UNAuthorizationOptionBadge;

        [center requestAuthorizationWithOptions:authOptions
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (error) {
                NSLog(@"[GodotxFirebaseMessaging] Permission request error: %@", error.localizedDescription);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (GodotxFirebaseMessaging::instance) {
                        GodotxFirebaseMessaging::instance->emit_signal("messaging_error", String([error.localizedDescription UTF8String]));
                    }
                });
                return;
            }

            NSLog(@"[GodotxFirebaseMessaging] Permission granted: %d", granted);

            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"[GodotxFirebaseMessaging] Calling registerForRemoteNotifications...");
                    [[UIApplication sharedApplication] registerForRemoteNotifications];

                    if (GodotxFirebaseMessaging::instance) {
                        GodotxFirebaseMessaging::instance->emit_signal("messaging_permission_granted");
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (GodotxFirebaseMessaging::instance) {
                        GodotxFirebaseMessaging::instance->emit_signal("messaging_permission_denied");
                    }
                });
            }
        }];
    }];
}

void GodotxFirebaseMessaging::get_token() {
    NSLog(@"[GodotxFirebaseMessaging] Getting FCM token...");

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
            NSLog(@"[GodotxFirebaseMessaging] Notification permission denied");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (GodotxFirebaseMessaging::instance) {
                    GodotxFirebaseMessaging::instance->emit_signal("messaging_error", String("Notification permission denied. Please enable notifications in iOS settings."));
                }
            });
            return;
        }

        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->attempt_get_fcm_token();
        }
    }];
}

void GodotxFirebaseMessaging::attempt_get_fcm_token() {
    NSLog(@"[GodotxFirebaseMessaging] Attempting to get FCM token...");

    [[FIRMessaging messaging] tokenWithCompletion:^(NSString * _Nullable token, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[GodotxFirebaseMessaging] Error fetching token: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (GodotxFirebaseMessaging::instance) {
                    GodotxFirebaseMessaging::instance->emit_signal("messaging_error", String([error.localizedDescription UTF8String]));
                }
            });
            return;
        }

        if (!token || token.length == 0) {
            NSLog(@"[GodotxFirebaseMessaging] FCM token is empty");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (GodotxFirebaseMessaging::instance) {
                    GodotxFirebaseMessaging::instance->emit_signal("messaging_error", String("FCM token is empty or nil."));
                }
            });
            return;
        }

        NSLog(@"[GodotxFirebaseMessaging] FCM token: %@", token);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (GodotxFirebaseMessaging::instance) {
                GodotxFirebaseMessaging::instance->emit_signal("messaging_token_received", String([token UTF8String]));
            }
        });
    }];
}

void GodotxFirebaseMessaging::get_apns_token() {
    NSLog(@"[GodotxFirebaseMessaging] Getting APNs token...");

    dispatch_async(dispatch_get_main_queue(), ^{
        NSData *apnsToken = [FIRMessaging messaging].APNSToken;

        if (apnsToken) {
            const unsigned char *data = (const unsigned char *)[apnsToken bytes];
            NSMutableString *token = [NSMutableString string];
            for (NSUInteger i = 0; i < [apnsToken length]; i++) {
                [token appendFormat:@"%02.2hhX", data[i]];
            }

            NSLog(@"[GodotxFirebaseMessaging] APNs Token: %@", token);

            if (GodotxFirebaseMessaging::instance) {
                GodotxFirebaseMessaging::instance->emit_signal("messaging_apn_token_received", String([token UTF8String]));
            }
        } else {
            NSLog(@"[GodotxFirebaseMessaging] APNs token not available yet. This may take a few seconds after registerForRemoteNotifications.");

            if (GodotxFirebaseMessaging::instance) {
                GodotxFirebaseMessaging::instance->emit_signal("messaging_error", String("APNs token not available yet. Make sure you called request_permission() and wait for the callback."));
            }
        }
    });
}

void GodotxFirebaseMessaging::subscribe_to_topic(String topic) {
    NSLog(@"[GodotxFirebaseMessaging] Subscribing to topic: %s", topic.utf8().get_data());

    NSString *nsTopic = [NSString stringWithUTF8String:topic.utf8().get_data()];

    [[FIRMessaging messaging] subscribeToTopic:nsTopic
                                     completion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"[GodotxFirebaseMessaging] Error subscribing to topic %@: %@", nsTopic, error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (GodotxFirebaseMessaging::instance) {
                    GodotxFirebaseMessaging::instance->emit_signal("messaging_error", String([error.localizedDescription UTF8String]));
                }
            });
        } else {
            NSLog(@"[GodotxFirebaseMessaging] Successfully subscribed to topic: %@", nsTopic);
        }
    }];
}

void GodotxFirebaseMessaging::unsubscribe_from_topic(String topic) {
    NSLog(@"[GodotxFirebaseMessaging] Unsubscribing from topic: %s", topic.utf8().get_data());

    NSString *nsTopic = [NSString stringWithUTF8String:topic.utf8().get_data()];

    [[FIRMessaging messaging] unsubscribeFromTopic:nsTopic
                                         completion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"[GodotxFirebaseMessaging] Error unsubscribing from topic %@: %@", nsTopic, error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (GodotxFirebaseMessaging::instance) {
                    GodotxFirebaseMessaging::instance->emit_signal("messaging_error", String([error.localizedDescription UTF8String]));
                }
            });
        } else {
            NSLog(@"[GodotxFirebaseMessaging] Successfully unsubscribed from topic: %@", nsTopic);
        }
    }];
}
