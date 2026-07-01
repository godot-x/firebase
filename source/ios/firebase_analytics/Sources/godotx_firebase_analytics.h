#ifndef GODOTX_FIREBASE_ANALYTICS_H
#define GODOTX_FIREBASE_ANALYTICS_H

#include "core/object/class_db.h"

class GodotxFirebaseAnalytics : public Object {
    GDCLASS(GodotxFirebaseAnalytics, Object);

private:
    static GodotxFirebaseAnalytics* instance;

protected:
    static void _bind_methods();

public:
    static GodotxFirebaseAnalytics* get_singleton();

    void initialize();
    void log_event(String event_name, Dictionary params);
    void set_consent(Dictionary consent);
    void set_analytics_collection_enabled(bool enabled);

    GodotxFirebaseAnalytics();
    ~GodotxFirebaseAnalytics();
};

#endif // GODOTX_FIREBASE_ANALYTICS_H

