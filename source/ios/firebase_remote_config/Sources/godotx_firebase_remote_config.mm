#import "godotx_firebase_remote_config.h"
#import <Foundation/Foundation.h>

@import Firebase;

#include "core/object/class_db.h"

GodotxFirebaseRemoteConfig *GodotxFirebaseRemoteConfig::instance = nullptr;

// Stored at file scope so the C++ header stays free of ObjC types.
// ARC manages lifetime: assigning nil releases the registration and stops the listener.
static FIRConfigUpdateListenerRegistration *_listenerRegistration = nil;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

static String string_from_ns(NSString *ns) {
    if (!ns) return String();
    return String::utf8([ns UTF8String]);
}

static NSString *ns_from_string(const String &s) {
    return [NSString stringWithUTF8String:s.utf8().get_data()];
}

static Dictionary ns_dict_to_godot(NSDictionary *nsDict);

static Variant ns_value_to_godot(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        return string_from_ns((NSString *)value);
    } else if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *num = (NSNumber *)value;
        if (strcmp([num objCType], @encode(BOOL)) == 0) {
            return (bool)[num boolValue];
        }
        return (double)[num doubleValue];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        return ns_dict_to_godot((NSDictionary *)value);
    }
    return Variant();
}

static Dictionary ns_dict_to_godot(NSDictionary *nsDict) {
    Dictionary dict;
    for (id key in nsDict) {
        String godot_key = string_from_ns([key description]);
        dict[godot_key] = ns_value_to_godot(nsDict[key]);
    }
    return dict;
}

#define FIREBASE_CHECK_INITIALIZED_V(ret) \
    if (![FIRApp defaultApp]) { \
        ERR_PRINT("Firebase not initialized. Call initialize() first."); \
        return ret; \
    }

#define FIREBASE_CHECK_INITIALIZED() \
    if (![FIRApp defaultApp]) { \
        ERR_PRINT("Firebase not initialized. Call initialize() first."); \
        return; \
    }

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

GodotxFirebaseRemoteConfig::GodotxFirebaseRemoteConfig() {
    ERR_FAIL_COND(instance != nullptr);
    instance = this;
}

GodotxFirebaseRemoteConfig::~GodotxFirebaseRemoteConfig() {
    [_listenerRegistration remove];
    _listenerRegistration = nil;
    if (instance == this) instance = nullptr;
}

GodotxFirebaseRemoteConfig *GodotxFirebaseRemoteConfig::get_singleton() {
    return instance;
}

// ---------------------------------------------------------------------------
// _bind_methods
// ---------------------------------------------------------------------------

void GodotxFirebaseRemoteConfig::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize"), &GodotxFirebaseRemoteConfig::initialize);
    ClassDB::bind_method(D_METHOD("fetch_and_activate"), &GodotxFirebaseRemoteConfig::fetch_and_activate);
    ClassDB::bind_method(D_METHOD("get_string", "key", "default_value"), &GodotxFirebaseRemoteConfig::get_string);
    ClassDB::bind_method(D_METHOD("get_int", "key", "default_value"), &GodotxFirebaseRemoteConfig::get_int);
    ClassDB::bind_method(D_METHOD("get_float", "key", "default_value"), &GodotxFirebaseRemoteConfig::get_float);
    ClassDB::bind_method(D_METHOD("get_double", "key", "default_value"), &GodotxFirebaseRemoteConfig::get_double);
    ClassDB::bind_method(D_METHOD("get_bool", "key", "default_value"), &GodotxFirebaseRemoteConfig::get_bool);
    ClassDB::bind_method(D_METHOD("get_dictionary", "key"), &GodotxFirebaseRemoteConfig::get_dictionary);
    ClassDB::bind_method(D_METHOD("set_defaults", "defaults"), &GodotxFirebaseRemoteConfig::set_defaults);
    ClassDB::bind_method(D_METHOD("set_minimum_fetch_interval", "seconds"), &GodotxFirebaseRemoteConfig::set_minimum_fetch_interval);
    ClassDB::bind_method(D_METHOD("setup_realtime_updates"), &GodotxFirebaseRemoteConfig::setup_realtime_updates);
    ClassDB::bind_method(D_METHOD("remove_config_update_listener"), &GodotxFirebaseRemoteConfig::remove_config_update_listener);

    ADD_SIGNAL(MethodInfo("remote_config_initialized", PropertyInfo(Variant::BOOL, "success")));
    ADD_SIGNAL(MethodInfo("remote_config_error", PropertyInfo(Variant::STRING, "message")));
    ADD_SIGNAL(MethodInfo("remote_config_fetch_completed", PropertyInfo(Variant::INT, "status")));
    ADD_SIGNAL(MethodInfo("remote_config_updated", PropertyInfo(Variant::ARRAY, "updated_keys")));
    ADD_SIGNAL(MethodInfo("remote_config_defaults_set"));
    ADD_SIGNAL(MethodInfo("remote_config_settings_updated"));
    ADD_SIGNAL(MethodInfo("remote_config_listener_registered"));
}

// ---------------------------------------------------------------------------
// initialize
// ---------------------------------------------------------------------------

void GodotxFirebaseRemoteConfig::initialize() {
    if (![FIRApp defaultApp]) {
        emit_signal("remote_config_initialized", false);
        emit_signal("remote_config_error", String("firebase_not_initialized"));
        return;
    }
    emit_signal("remote_config_initialized", true);
}

// ---------------------------------------------------------------------------
// fetch_and_activate
// FetchStatus: 0=SUCCESS, 1=CACHED, 2=FAILURE, 3=THROTTLED
// ---------------------------------------------------------------------------

void GodotxFirebaseRemoteConfig::fetch_and_activate() {
    FIREBASE_CHECK_INITIALIZED();
    FIRRemoteConfig *rc = [FIRRemoteConfig remoteConfig];
    [rc fetchAndActivateWithCompletionHandler:^(FIRRemoteConfigFetchAndActivateStatus status,
                                                NSError *error) {
        int godot_status;
        switch (status) {
            case FIRRemoteConfigFetchAndActivateStatusSuccessFetchedFromRemote:
                godot_status = 0;
                break;
            case FIRRemoteConfigFetchAndActivateStatusSuccessUsingPreFetchedData:
                godot_status = 1;
                break;
            case FIRRemoteConfigFetchAndActivateStatusError:
                godot_status = (error && error.code == FIRRemoteConfigErrorThrottled) ? 3 : 2;
                break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (GodotxFirebaseRemoteConfig::instance) {
                GodotxFirebaseRemoteConfig::instance->emit_signal("remote_config_fetch_completed", godot_status);
            }
        });
    }];
}

// ---------------------------------------------------------------------------
// Value getters — return default_value when source is Static (key unknown)
// ---------------------------------------------------------------------------

String GodotxFirebaseRemoteConfig::get_string(const String &key, const String &default_value) {
    FIREBASE_CHECK_INITIALIZED_V(default_value);
    FIRRemoteConfigValue *value = [FIRRemoteConfig remoteConfig][ns_from_string(key)];
    if (value.source == FIRRemoteConfigSourceStatic) return default_value;
    return string_from_ns(value.stringValue);
}

int GodotxFirebaseRemoteConfig::get_int(const String &key, int default_value) {
    FIREBASE_CHECK_INITIALIZED_V(default_value);
    FIRRemoteConfigValue *value = [FIRRemoteConfig remoteConfig][ns_from_string(key)];
    if (value.source == FIRRemoteConfigSourceStatic) return default_value;
    return [value.numberValue intValue];
}

float GodotxFirebaseRemoteConfig::get_float(const String &key, float default_value) {
    FIREBASE_CHECK_INITIALIZED_V(default_value);
    FIRRemoteConfigValue *value = [FIRRemoteConfig remoteConfig][ns_from_string(key)];
    if (value.source == FIRRemoteConfigSourceStatic) return default_value;
    return [value.numberValue floatValue];
}

double GodotxFirebaseRemoteConfig::get_double(const String &key, double default_value) {
    FIREBASE_CHECK_INITIALIZED_V(default_value);
    FIRRemoteConfigValue *value = [FIRRemoteConfig remoteConfig][ns_from_string(key)];
    if (value.source == FIRRemoteConfigSourceStatic) return default_value;
    return [value.numberValue doubleValue];
}

int GodotxFirebaseRemoteConfig::get_bool(const String &key, bool default_value) {
    FIREBASE_CHECK_INITIALIZED_V(default_value ? 1 : 0);
    FIRRemoteConfigValue *value = [FIRRemoteConfig remoteConfig][ns_from_string(key)];
    bool boolVal = (value.source == FIRRemoteConfigSourceStatic) ? default_value : value.boolValue;
    return boolVal ? 1 : 0;
}

Dictionary GodotxFirebaseRemoteConfig::get_dictionary(const String &key) {
    FIREBASE_CHECK_INITIALIZED_V(Dictionary());
    FIRRemoteConfigValue *value = [FIRRemoteConfig remoteConfig][ns_from_string(key)];
    id json = value.JSONValue;
    if (![json isKindOfClass:[NSDictionary class]]) return Dictionary();
    return ns_dict_to_godot((NSDictionary *)json);
}

// ---------------------------------------------------------------------------
// Defaults & settings
// ---------------------------------------------------------------------------

void GodotxFirebaseRemoteConfig::set_defaults(const Dictionary &defaults) {
    FIREBASE_CHECK_INITIALIZED();
    NSMutableDictionary *nsDefaults = [NSMutableDictionary dictionary];
    Array keys = defaults.keys();
    for (int i = 0; i < keys.size(); i++) {
        String key = keys[i];
        Variant val = defaults[key];
        NSString *nsKey = ns_from_string(key);
        if (val.get_type() == Variant::STRING) {
            nsDefaults[nsKey] = ns_from_string(String(val));
        } else if (val.get_type() == Variant::INT) {
            nsDefaults[nsKey] = @((int64_t)val);
        } else if (val.get_type() == Variant::FLOAT) {
            nsDefaults[nsKey] = @((double)val);
        } else if (val.get_type() == Variant::BOOL) {
            nsDefaults[nsKey] = @((bool)val);
        }
    }
    [[FIRRemoteConfig remoteConfig] setDefaults:nsDefaults];
    emit_signal("remote_config_defaults_set");
}

void GodotxFirebaseRemoteConfig::set_minimum_fetch_interval(float seconds) {
    FIREBASE_CHECK_INITIALIZED();
    FIRRemoteConfigSettings *settings = [[FIRRemoteConfigSettings alloc] init];
    settings.minimumFetchInterval = (NSTimeInterval)seconds;
    [FIRRemoteConfig remoteConfig].configSettings = settings;
    emit_signal("remote_config_settings_updated");
}

// ---------------------------------------------------------------------------
// Real-time listener
// ---------------------------------------------------------------------------

void GodotxFirebaseRemoteConfig::setup_realtime_updates() {
    FIREBASE_CHECK_INITIALIZED();
    if (_listenerRegistration) {
        emit_signal("remote_config_listener_registered");
        return;
    }
    FIRRemoteConfig *rc = [FIRRemoteConfig remoteConfig];
    _listenerRegistration = [rc addOnConfigUpdateListener:^(FIRRemoteConfigUpdate *update,
                                                             NSError *error) {
        if (error) { return; }
        [rc activateWithCompletion:^(BOOL changed, NSError *err) {
            Array keys;
            for (NSString *k in update.updatedKeys) {
                keys.push_back(string_from_ns(k));
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (GodotxFirebaseRemoteConfig::instance) {
                    GodotxFirebaseRemoteConfig::instance->emit_signal("remote_config_updated", keys);
                }
            });
        }];
    }];
    emit_signal("remote_config_listener_registered");
}

void GodotxFirebaseRemoteConfig::remove_config_update_listener() {
    [_listenerRegistration remove];
    _listenerRegistration = nil;
}
