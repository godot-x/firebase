#import "godotx_firebase_analytics.h"
#import <Foundation/Foundation.h>

@import FirebaseAnalytics;

#include "core/object/class_db.h"

GodotxFirebaseAnalytics* GodotxFirebaseAnalytics::instance = nullptr;

void GodotxFirebaseAnalytics::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize"), &GodotxFirebaseAnalytics::initialize);
    ClassDB::bind_method(D_METHOD("log_event", "event_name", "params"), &GodotxFirebaseAnalytics::log_event);
    ClassDB::bind_method(D_METHOD("set_consent", "consent"), &GodotxFirebaseAnalytics::set_consent);
    ClassDB::bind_method(D_METHOD("set_analytics_collection_enabled", "enabled"), &GodotxFirebaseAnalytics::set_analytics_collection_enabled);

    ADD_SIGNAL(MethodInfo("analytics_initialized", PropertyInfo(Variant::BOOL, "success")));
    ADD_SIGNAL(MethodInfo("analytics_event_logged", PropertyInfo(Variant::STRING, "event_name")));
    ADD_SIGNAL(MethodInfo("analytics_error", PropertyInfo(Variant::STRING, "message")));
}

static NSDictionary* dictionary_to_nsdict(const Dictionary& dict) {
    NSMutableDictionary* nsDict = [NSMutableDictionary dictionary];
    Array keys = dict.keys();

    for (int i = 0; i < keys.size(); i++) {
        String key = keys[i];
        Variant value = dict[key];

        NSString* nsKey = [NSString stringWithUTF8String:key.utf8().get_data()];

        if (value.get_type() == Variant::STRING) {
            nsDict[nsKey] = [NSString stringWithUTF8String:String(value).utf8().get_data()];
        } else if (value.get_type() == Variant::INT) {
            nsDict[nsKey] = @((int64_t)value);
        } else if (value.get_type() == Variant::FLOAT) {
            nsDict[nsKey] = @((double)value);
        } else if (value.get_type() == Variant::BOOL) {
            // firebase analytics does NOT support boolean
            nsDict[nsKey] = @((bool)value ? 1 : 0);
        }
    }

    return nsDict;
}

GodotxFirebaseAnalytics* GodotxFirebaseAnalytics::get_singleton() {
    return instance;
}

void GodotxFirebaseAnalytics::initialize() {
    emit_signal("analytics_initialized", true);
}

void GodotxFirebaseAnalytics::log_event(String event_name, Dictionary params) {
    NSLog(@"[GodotxFirebaseAnalytics] log_event: %s", event_name.utf8().get_data());

    @try {
        NSString* nsEventName = [NSString stringWithUTF8String:event_name.utf8().get_data()];
        NSDictionary* nsParams = dictionary_to_nsdict(params);

        [FIRAnalytics logEventWithName:nsEventName parameters:nsParams];

        emit_signal("analytics_event_logged", event_name);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to log event: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

static void put_consent(NSMutableDictionary* map, const Dictionary& consent, const char* key, FIRConsentType type) {
    if (!consent.has(key)) {
        return;
    }
    // FIRConsentType / FIRConsentStatus are NSString-based typed enums, so the
    // constants are used directly as keys/values (no NSNumber boxing).
    String value = consent[key];
    map[type] = (value == "granted") ? FIRConsentStatusGranted : FIRConsentStatusDenied;
}

void GodotxFirebaseAnalytics::set_consent(Dictionary consent) {
    @try {
        NSMutableDictionary* map = [NSMutableDictionary dictionary];
        put_consent(map, consent, "analytics_storage", FIRConsentTypeAnalyticsStorage);
        put_consent(map, consent, "ad_storage", FIRConsentTypeAdStorage);
        put_consent(map, consent, "ad_user_data", FIRConsentTypeAdUserData);
        put_consent(map, consent, "ad_personalization", FIRConsentTypeAdPersonalization);
        if (map.count > 0) {
            [FIRAnalytics setConsent:map];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to set consent: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseAnalytics::set_analytics_collection_enabled(bool enabled) {
    @try {
        [FIRAnalytics setAnalyticsCollectionEnabled:enabled];
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to set analytics collection enabled: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

GodotxFirebaseAnalytics::GodotxFirebaseAnalytics() {
    ERR_FAIL_COND(instance != NULL);
    instance = this;
    NSLog(@"[GodotxFirebaseAnalytics] Created");
}

GodotxFirebaseAnalytics::~GodotxFirebaseAnalytics() {
    if (instance == this) {
        instance = nullptr;
    }
}

