#import "godotx_firebase_analytics.h"
#import <Foundation/Foundation.h>

@import FirebaseAnalytics;

#include "core/object/class_db.h"

GodotxFirebaseAnalytics* GodotxFirebaseAnalytics::instance = nullptr;

void GodotxFirebaseAnalytics::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize"), &GodotxFirebaseAnalytics::initialize);
    ClassDB::bind_method(D_METHOD("log_event", "event_name", "params"), &GodotxFirebaseAnalytics::log_event);
    ClassDB::bind_method(D_METHOD("log_screen_view", "screen_name", "screen_class"), &GodotxFirebaseAnalytics::log_screen_view);
    ClassDB::bind_method(D_METHOD("set_user_property", "name", "value"), &GodotxFirebaseAnalytics::set_user_property);
    ClassDB::bind_method(D_METHOD("set_user_id", "user_id"), &GodotxFirebaseAnalytics::set_user_id);
    ClassDB::bind_method(D_METHOD("set_default_event_parameters", "params"), &GodotxFirebaseAnalytics::set_default_event_parameters);
    ClassDB::bind_method(D_METHOD("set_collection_enabled", "enabled"), &GodotxFirebaseAnalytics::set_collection_enabled);
    ClassDB::bind_method(D_METHOD("reset_analytics_data"), &GodotxFirebaseAnalytics::reset_analytics_data);
    ClassDB::bind_method(D_METHOD("set_consent", "consent_data"), &GodotxFirebaseAnalytics::set_consent);

    ClassDB::bind_method(D_METHOD("log_level_start", "level_name"), &GodotxFirebaseAnalytics::log_level_start);
    ClassDB::bind_method(D_METHOD("log_level_end", "level_name", "success"), &GodotxFirebaseAnalytics::log_level_end);
    ClassDB::bind_method(D_METHOD("log_earn_currency", "currency_name", "value"), &GodotxFirebaseAnalytics::log_earn_currency);
    ClassDB::bind_method(D_METHOD("log_spend_currency", "currency_name", "value", "item_name"), &GodotxFirebaseAnalytics::log_spend_currency);
    ClassDB::bind_method(D_METHOD("log_tutorial_begin"), &GodotxFirebaseAnalytics::log_tutorial_begin);
    ClassDB::bind_method(D_METHOD("log_tutorial_complete"), &GodotxFirebaseAnalytics::log_tutorial_complete);
    ClassDB::bind_method(D_METHOD("log_post_score", "score", "board", "character"), &GodotxFirebaseAnalytics::log_post_score, DEFVAL(""), DEFVAL(""));
    ClassDB::bind_method(D_METHOD("log_unlock_achievement", "id"), &GodotxFirebaseAnalytics::log_unlock_achievement);

    ADD_SIGNAL(MethodInfo("analytics_initialized", PropertyInfo(Variant::BOOL, "success")));
    ADD_SIGNAL(MethodInfo("analytics_event_logged", PropertyInfo(Variant::STRING, "event_name")));
    ADD_SIGNAL(MethodInfo("analytics_screen_logged", PropertyInfo(Variant::STRING, "screen_name")));
    ADD_SIGNAL(MethodInfo("analytics_property_set", PropertyInfo(Variant::STRING, "name")));
    ADD_SIGNAL(MethodInfo("analytics_user_id_set", PropertyInfo(Variant::STRING, "user_id")));
    ADD_SIGNAL(MethodInfo("analytics_default_params_set"));
    ADD_SIGNAL(MethodInfo("analytics_collection_enabled_set", PropertyInfo(Variant::BOOL, "enabled")));
    ADD_SIGNAL(MethodInfo("analytics_data_reset"));
    ADD_SIGNAL(MethodInfo("analytics_consent_set"));
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

void GodotxFirebaseAnalytics::log_screen_view(String screen_name, String screen_class) {
    NSLog(@"[GodotxFirebaseAnalytics] log_screen_view: %s (%s)", screen_name.utf8().get_data(), screen_class.utf8().get_data());

    @try {
        NSString* nsScreenName = [NSString stringWithUTF8String:screen_name.utf8().get_data()];
        NSString* nsScreenClass = [NSString stringWithUTF8String:screen_class.utf8().get_data()];

        [FIRAnalytics logEventWithName:kFIREventScreenView
                            parameters:@{
                                kFIRParameterScreenName: nsScreenName,
                                kFIRParameterScreenClass: nsScreenClass
                            }];

        emit_signal("analytics_screen_logged", screen_name);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to log screen view: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseAnalytics::set_user_property(String name, String value) {
    NSLog(@"[GodotxFirebaseAnalytics] set_user_property: %s = %s", name.utf8().get_data(), value.utf8().get_data());

    @try {
        NSString* nsName = [NSString stringWithUTF8String:name.utf8().get_data()];
        NSString* nsValue = [NSString stringWithUTF8String:value.utf8().get_data()];

        [FIRAnalytics setUserPropertyString:nsValue forName:nsName];

        emit_signal("analytics_property_set", name);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to set user property: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseAnalytics::set_user_id(String user_id) {
    NSLog(@"[GodotxFirebaseAnalytics] set_user_id: %s", user_id.utf8().get_data());
    @try {
        NSString* nsUserId = [NSString stringWithUTF8String:user_id.utf8().get_data()];
        [FIRAnalytics setUserID:nsUserId];
        emit_signal("analytics_user_id_set", user_id);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to set user id: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseAnalytics::set_default_event_parameters(Dictionary params) {
    NSLog(@"[GodotxFirebaseAnalytics] set_default_event_parameters");
    @try {
        NSDictionary* nsParams = dictionary_to_nsdict(params);
        [FIRAnalytics setDefaultEventParameters:nsParams];
        emit_signal("analytics_default_params_set");
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to set default parameters: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseAnalytics::set_collection_enabled(bool enabled) {
    NSLog(@"[GodotxFirebaseAnalytics] set_collection_enabled: %d", enabled);
    @try {
        [FIRAnalytics setAnalyticsCollectionEnabled:enabled];
        emit_signal("analytics_collection_enabled_set", enabled);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to set collection enabled: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseAnalytics::reset_analytics_data() {
    NSLog(@"[GodotxFirebaseAnalytics] reset_analytics_data");
    @try {
        [FIRAnalytics resetAnalyticsData];
        emit_signal("analytics_data_reset");
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to reset analytics data: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseAnalytics::set_consent(Dictionary consent_data) {
    NSLog(@"[GodotxFirebaseAnalytics] set_consent");
    @try {
        NSMutableDictionary<FIRConsentType, FIRConsentStatus> *consentMap = [NSMutableDictionary dictionary];

        if (consent_data.has("ad_storage") && consent_data["ad_storage"].get_type() == Variant::BOOL) {
            bool val = consent_data["ad_storage"];
            consentMap[FIRConsentTypeAdStorage] = val ? FIRConsentStatusGranted : FIRConsentStatusDenied;
        }

        if (consent_data.has("analytics_storage") && consent_data["analytics_storage"].get_type() == Variant::BOOL) {
            bool val = consent_data["analytics_storage"];
            consentMap[FIRConsentTypeAnalyticsStorage] = val ? FIRConsentStatusGranted : FIRConsentStatusDenied;
        }

        if (consent_data.has("ad_user_data") && consent_data["ad_user_data"].get_type() == Variant::BOOL) {
            bool val = consent_data["ad_user_data"];
            consentMap[FIRConsentTypeAdUserData] = val ? FIRConsentStatusGranted : FIRConsentStatusDenied;
        }

        if (consent_data.has("ad_personalization") && consent_data["ad_personalization"].get_type() == Variant::BOOL) {
            bool val = consent_data["ad_personalization"];
            consentMap[FIRConsentTypeAdPersonalization] = val ? FIRConsentStatusGranted : FIRConsentStatusDenied;
        }

        [FIRAnalytics setConsent:consentMap];
        emit_signal("analytics_consent_set");
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to set consent: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseAnalytics::log_level_start(String level_name) {
    Dictionary params;
    params["level_name"] = level_name;
    log_event(String(kFIREventLevelStart.UTF8String), params);
}

void GodotxFirebaseAnalytics::log_level_end(String level_name, bool success) {
    Dictionary params;
    params["level_name"] = level_name;
    params["success"] = success ? 1 : 0;
    log_event(String(kFIREventLevelEnd.UTF8String), params);
}

void GodotxFirebaseAnalytics::log_earn_currency(String currency_name, float value) {
    Dictionary params;
    params["virtual_currency_name"] = currency_name;
    params["value"] = value;
    log_event(String(kFIREventEarnVirtualCurrency.UTF8String), params);
}

void GodotxFirebaseAnalytics::log_spend_currency(String currency_name, float value, String item_name) {
    Dictionary params;
    params["virtual_currency_name"] = currency_name;
    params["value"] = value;
    params["item_name"] = item_name;
    log_event(String(kFIREventSpendVirtualCurrency.UTF8String), params);
}

void GodotxFirebaseAnalytics::log_tutorial_begin() {
    log_event(String(kFIREventTutorialBegin.UTF8String), Dictionary());
}

void GodotxFirebaseAnalytics::log_tutorial_complete() {
    log_event(String(kFIREventTutorialComplete.UTF8String), Dictionary());
}

void GodotxFirebaseAnalytics::log_post_score(int64_t score, String board, String character) {
    Dictionary params;
    params[String(kFIRParameterScore.UTF8String)] = score;
    if (!board.is_empty()) {
        params[String(kFIRParameterLevelName.UTF8String)] = board;
    }
    if (!character.is_empty()) {
        params[String(kFIRParameterCharacter.UTF8String)] = character;
    }
    log_event(String(kFIREventPostScore.UTF8String), params);
}

void GodotxFirebaseAnalytics::log_unlock_achievement(String achievement_id) {
    Dictionary params;
    params[String(kFIRParameterAchievementID.UTF8String)] = achievement_id;
    log_event(String(kFIREventUnlockAchievement.UTF8String), params);
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

