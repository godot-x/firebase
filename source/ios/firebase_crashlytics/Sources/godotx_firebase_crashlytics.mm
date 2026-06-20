#import "godotx_firebase_crashlytics.h"
#import <Foundation/Foundation.h>

@import Firebase;

#include "core/object/class_db.h"

GodotxFirebaseCrashlytics* GodotxFirebaseCrashlytics::instance = nullptr;

void GodotxFirebaseCrashlytics::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize"), &GodotxFirebaseCrashlytics::initialize);
    ClassDB::bind_method(D_METHOD("crash"), &GodotxFirebaseCrashlytics::crash);
    ClassDB::bind_method(D_METHOD("log_non_fatal", "message"), &GodotxFirebaseCrashlytics::log_non_fatal);
    ClassDB::bind_method(D_METHOD("log_message", "message"), &GodotxFirebaseCrashlytics::log_message);
    ClassDB::bind_method(D_METHOD("set_user_id", "user_id"), &GodotxFirebaseCrashlytics::set_user_id);
    ClassDB::bind_method(D_METHOD("set_custom_value", "key", "value"), &GodotxFirebaseCrashlytics::set_custom_value);

    ADD_SIGNAL(MethodInfo("crashlytics_initialized", PropertyInfo(Variant::BOOL, "success")));
    ADD_SIGNAL(MethodInfo("crashlytics_non_fatal_logged", PropertyInfo(Variant::STRING, "message")));
    ADD_SIGNAL(MethodInfo("crashlytics_message_logged", PropertyInfo(Variant::STRING, "message")));
    ADD_SIGNAL(MethodInfo("crashlytics_value_set", PropertyInfo(Variant::STRING, "key")));
    ADD_SIGNAL(MethodInfo("crashlytics_user_id_set", PropertyInfo(Variant::STRING, "user_id")));
    ADD_SIGNAL(MethodInfo("crashlytics_error", PropertyInfo(Variant::STRING, "message")));
}

GodotxFirebaseCrashlytics* GodotxFirebaseCrashlytics::get_singleton() {
    return instance;
}

void GodotxFirebaseCrashlytics::initialize() {
    emit_signal("crashlytics_initialized", true);
}

void GodotxFirebaseCrashlytics::crash() {
    NSLog(@"[GodotxFirebaseCrashlytics] Forcing crash for testing...");
    @[][1];
}

void GodotxFirebaseCrashlytics::log_non_fatal(String message) {
    @try {
        NSString* nsMessage = [NSString stringWithUTF8String:message.utf8().get_data()];
        NSError* error = [NSError errorWithDomain:@"GodotxFirebaseHarness"
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: nsMessage}];
        [[FIRCrashlytics crashlytics] recordError:error];
        NSLog(@"[GodotxFirebaseCrashlytics] Recorded non-fatal exception: %@", nsMessage);
        emit_signal("crashlytics_non_fatal_logged", message);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to record non-fatal: %@", exception.reason);
        emit_signal("crashlytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseCrashlytics::log_message(String message) {
    @try {
        NSString* nsMessage = [NSString stringWithUTF8String:message.utf8().get_data()];
        [[FIRCrashlytics crashlytics] log:nsMessage];
        NSLog(@"[GodotxFirebaseCrashlytics] Logged message: %@", nsMessage);
        emit_signal("crashlytics_message_logged", message);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to log message: %@", exception.reason);
        emit_signal("crashlytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseCrashlytics::set_user_id(String user_id) {
    @try {
        NSString* nsUserId = [NSString stringWithUTF8String:user_id.utf8().get_data()];
        [[FIRCrashlytics crashlytics] setUserID:nsUserId];
        NSLog(@"[GodotxFirebaseCrashlytics] Set user ID: %@", nsUserId);
        emit_signal("crashlytics_user_id_set", user_id);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to set user ID: %@", exception.reason);
        emit_signal("crashlytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseCrashlytics::set_custom_value(String key, String value) {
    @try {
        NSString *nsKey = [NSString stringWithUTF8String:key.utf8().get_data()];
        NSString *nsValue = [NSString stringWithUTF8String:value.utf8().get_data()];
        [[FIRCrashlytics crashlytics] setCustomValue:nsValue forKey:nsKey];
        NSLog(@"[GodotxFirebaseCrashlytics] Set custom value: %@ = %@", nsKey, nsValue);
        emit_signal("crashlytics_value_set", key);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to set custom value: %@", exception.reason);
        emit_signal("crashlytics_error", String::utf8([exception.reason UTF8String]));
    }
}

GodotxFirebaseCrashlytics::GodotxFirebaseCrashlytics() {
    ERR_FAIL_COND(instance != NULL);
    instance = this;
    NSLog(@"[GodotxFirebaseCrashlytics] Created");
}

GodotxFirebaseCrashlytics::~GodotxFirebaseCrashlytics() {
    if (instance == this) {
        instance = nullptr;
    }
}

