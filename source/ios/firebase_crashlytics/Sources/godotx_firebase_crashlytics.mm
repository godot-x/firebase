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
    ClassDB::bind_method(D_METHOD("set_custom_value_string", "key", "value"), &GodotxFirebaseCrashlytics::set_custom_value_string);
    ClassDB::bind_method(D_METHOD("set_custom_value_int", "key", "value"), &GodotxFirebaseCrashlytics::set_custom_value_int);
    ClassDB::bind_method(D_METHOD("set_custom_value_bool", "key", "value"), &GodotxFirebaseCrashlytics::set_custom_value_bool);
    ClassDB::bind_method(D_METHOD("set_custom_value_float", "key", "value"), &GodotxFirebaseCrashlytics::set_custom_value_float);
    ClassDB::bind_method(D_METHOD("record_error", "name", "message", "frames"), &GodotxFirebaseCrashlytics::record_error);
    ClassDB::bind_method(D_METHOD("set_crashlytics_collection_enabled", "enabled"), &GodotxFirebaseCrashlytics::set_crashlytics_collection_enabled);

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

void GodotxFirebaseCrashlytics::set_custom_value_string(String key, String value) {
    @try {
        NSString* nsKey = [NSString stringWithUTF8String:key.utf8().get_data()];
        NSString* nsValue = [NSString stringWithUTF8String:value.utf8().get_data()];
        [[FIRCrashlytics crashlytics] setCustomValue:nsValue forKey:nsKey];
        NSLog(@"[GodotxFirebaseCrashlytics] Set custom value: %@ = %@", nsKey, nsValue);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to set custom value: %@", exception.reason);
        emit_signal("crashlytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseCrashlytics::set_custom_value_int(String key, int64_t value) {
    @try {
        NSString* nsKey = [NSString stringWithUTF8String:key.utf8().get_data()];
        [[FIRCrashlytics crashlytics] setCustomValue:@(value) forKey:nsKey];
        NSLog(@"[GodotxFirebaseCrashlytics] Set custom value: %@ = %lld", nsKey, value);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to set custom value: %@", exception.reason);
        emit_signal("crashlytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseCrashlytics::set_custom_value_bool(String key, bool value) {
    @try {
        NSString* nsKey = [NSString stringWithUTF8String:key.utf8().get_data()];
        [[FIRCrashlytics crashlytics] setCustomValue:@(value) forKey:nsKey];
        NSLog(@"[GodotxFirebaseCrashlytics] Set custom value: %@ = %d", nsKey, value);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to set custom value: %@", exception.reason);
        emit_signal("crashlytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseCrashlytics::set_custom_value_float(String key, double value) {
    @try {
        NSString* nsKey = [NSString stringWithUTF8String:key.utf8().get_data()];
        [[FIRCrashlytics crashlytics] setCustomValue:@(value) forKey:nsKey];
        NSLog(@"[GodotxFirebaseCrashlytics] Set custom value: %@ = %f", nsKey, value);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to set custom value: %@", exception.reason);
        emit_signal("crashlytics_error", String::utf8([exception.reason UTF8String]));
    }
}

// Records a non-fatal error, such as a script error the engine survived.
// Each frame is "function<TAB>file<TAB>line", innermost first.
void GodotxFirebaseCrashlytics::record_error(String name, String message, PackedStringArray frames) {
    @try {
        NSString* nsName = [NSString stringWithUTF8String:name.utf8().get_data()];
        NSString* nsMessage = [NSString stringWithUTF8String:message.utf8().get_data()];
        FIRExceptionModel* model = [FIRExceptionModel exceptionModelWithName:nsName reason:nsMessage];
        NSMutableArray<FIRStackFrame*>* stack = [NSMutableArray array];
        for (int i = 0; i < frames.size(); i++) {
            PackedStringArray parts = frames[i].split("\t");
            NSString* symbol = [NSString stringWithUTF8String:(parts.size() > 0 ? parts[0] : String()).utf8().get_data()];
            NSString* file = [NSString stringWithUTF8String:(parts.size() > 1 ? parts[1] : String()).utf8().get_data()];
            NSInteger line = parts.size() > 2 ? parts[2].to_int() : 0;
            [stack addObject:[FIRStackFrame stackFrameWithSymbol:symbol file:file line:line]];
        }
        model.stackTrace = stack;
        [[FIRCrashlytics crashlytics] recordExceptionModel:model];
        NSLog(@"[GodotxFirebaseCrashlytics] Recorded error: %@: %@", nsName, nsMessage);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to record error: %@", exception.reason);
        emit_signal("crashlytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseCrashlytics::set_crashlytics_collection_enabled(bool enabled) {
    @try {
        [[FIRCrashlytics crashlytics] setCrashlyticsCollectionEnabled:enabled];
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCrashlytics] Failed to set crashlytics collection enabled: %@", exception.reason);
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

