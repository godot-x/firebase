#ifndef GODOTX_FIREBASE_REMOTE_CONFIG_H
#define GODOTX_FIREBASE_REMOTE_CONFIG_H

#include "core/object/class_db.h"

class GodotxFirebaseRemoteConfig : public Object {
    GDCLASS(GodotxFirebaseRemoteConfig, Object);

private:
    static GodotxFirebaseRemoteConfig *instance;

protected:
    static void _bind_methods();

public:
    static GodotxFirebaseRemoteConfig *get_singleton();

    void initialize();
    void fetch_and_activate();
    String get_string(const String &key, const String &default_value);
    int get_int(const String &key, int default_value);
    float get_float(const String &key, float default_value);
    double get_double(const String &key, double default_value);
    int get_bool(const String &key, bool default_value);
    Dictionary get_dictionary(const String &key);
    void set_defaults(const Dictionary &defaults);
    void set_minimum_fetch_interval(float seconds);
    void setup_realtime_updates();
    void remove_config_update_listener();

    GodotxFirebaseRemoteConfig();
    ~GodotxFirebaseRemoteConfig();
};

#endif // GODOTX_FIREBASE_REMOTE_CONFIG_H
