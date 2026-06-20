#ifndef GODOTX_FIREBASE_CRASHLYTICS_H
#define GODOTX_FIREBASE_CRASHLYTICS_H

#include "core/object/class_db.h"

class GodotxFirebaseCrashlytics : public Object {
    GDCLASS(GodotxFirebaseCrashlytics, Object);

private:
    static GodotxFirebaseCrashlytics* instance;

protected:
    static void _bind_methods();

public:
    static GodotxFirebaseCrashlytics* get_singleton();

    void initialize();
    void crash();
    void log_non_fatal(String message);
    void log_message(String message);
    void set_user_id(String user_id);
    void set_custom_value(String key, String value);

    GodotxFirebaseCrashlytics();
    ~GodotxFirebaseCrashlytics();
};

#endif // GODOTX_FIREBASE_CRASHLYTICS_H

