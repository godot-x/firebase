#import "godotx_firebase_crashlytics.h"
#import <Foundation/Foundation.h>

@import Firebase;

#include "core/object/class_db.h"

GodotxFirebaseCrashlytics* GodotxFirebaseCrashlytics::instance = nullptr;

void GodotxFirebaseCrashlytics::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize"), &GodotxFirebaseCrashlytics::initialize);
    ClassDB::bind_method(D_METHOD("crash"), &GodotxFirebaseCrashlytics::crash);
    ClassDB::bind_method(D_METHOD("log_message", "message"), &GodotxFirebaseCrashlytics::log_message);
    ClassDB::bind_method(D_METHOD("set_user_id", "user_id"), &GodotxFirebaseCrashlytics::set_user_id);
    ClassDB::bind_method(D_METHOD("set_custom_value", "key", "value"), &GodotxFirebaseCrashlytics::set_custom_value);

    ADD_SIGNAL(MethodInfo("crashlytics_initialized", PropertyInfo(Variant::BOOL, "success")));
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

void GodotxFirebaseCrashlytics::log_message(String message) {
    @try {
        NSString* nsMessage = [NSString stringWithUTF8String:message.utf8().get_data()];
        [[FIRCrashlytics crashlytics] log:nsMessage];
        NSLog(@"[GodotxFirebaseCrashlytics] Logged message: %@", nsMessage);
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
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to set user ID: %@", exception.reason);
        emit_signal("crashlytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseCrashlytics::set_custom_value(String key, Variant value) {
    @try {
        NSString* nsKey = [NSString stringWithUTF8String:key.utf8().get_data()];
        id nsValue = nil;
        switch (value.get_type()) {
            case Variant::BOOL:
                nsValue = @((bool)value);
                break;
            case Variant::INT:
                nsValue = @((int64_t)value);
                break;
            case Variant::FLOAT:
                nsValue = @((double)value);
                break;
            case Variant::STRING:
                nsValue = [NSString stringWithUTF8String:String(value).utf8().get_data()];
                break;
            default:
                nsValue = [NSString stringWithUTF8String:String(value).utf8().get_data()];
                break;
        }
        [[FIRCrashlytics crashlytics] setCustomValue:nsValue forKey:nsKey];
        NSLog(@"[GodotxFirebaseCrashlytics] Set custom value: %@ = %@", nsKey, nsValue);
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

