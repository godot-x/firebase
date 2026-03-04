#import "godotx_firebase_core.h"
#import <Foundation/Foundation.h>

@import Firebase;

#include "core/object/class_db.h"

GodotxFirebaseCore* GodotxFirebaseCore::instance = nullptr;

void GodotxFirebaseCore::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize"), &GodotxFirebaseCore::initialize);
    ClassDB::bind_method(D_METHOD("is_ready"), &GodotxFirebaseCore::is_ready);

    ADD_SIGNAL(MethodInfo("core_initialized", PropertyInfo(Variant::BOOL, "success")));
    ADD_SIGNAL(MethodInfo("core_error", PropertyInfo(Variant::STRING, "message")));
}

GodotxFirebaseCore* GodotxFirebaseCore::get_singleton() {
    return instance;
}

void GodotxFirebaseCore::initialize() {
    NSLog(@"[GodotxFirebaseCore] initialize() called");

    if (is_initialized) {
        NSLog(@"[GodotxFirebaseCore] Already initialized");
        emit_signal("core_initialized", true);
        return;
    }

    @try {
        if ([FIRApp defaultApp] == nil) {
            [FIRApp configure];
            NSLog(@"[GodotxFirebaseCore] Firebase configured");
        }

        is_initialized = true;
        emit_signal("core_initialized", true);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseCore] Firebase initialization failed: %@", exception.reason);
        emit_signal("core_initialized", false);
        emit_signal("core_error", String::utf8([exception.reason UTF8String]));
    }
}

bool GodotxFirebaseCore::is_ready() const {
    return is_initialized;
}

GodotxFirebaseCore::GodotxFirebaseCore() {
    ERR_FAIL_COND(instance != NULL);
    instance = this;
    is_initialized = false;
    NSLog(@"[GodotxFirebaseCore] Created");
}

GodotxFirebaseCore::~GodotxFirebaseCore() {
    if (instance == this) {
        instance = nullptr;
    }
}

