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
    void log_screen_view(String screen_name, String screen_class);
    void set_user_property(String name, String value);
    void set_user_id(String user_id);
    void set_default_event_parameters(Dictionary params);
    void set_collection_enabled(bool enabled);
    void reset_analytics_data();
    void set_consent(Dictionary consent_data);

    void log_level_start(String level_name);
    void log_level_end(String level_name, bool success);
    void log_earn_currency(String currency_name, float value);
    void log_spend_currency(String currency_name, float value, String item_name);
    void log_tutorial_begin();
    void log_tutorial_complete();
    void log_post_score(int64_t score, String board, String character);
    void log_unlock_achievement(String achievement_id);

    GodotxFirebaseAnalytics();
    ~GodotxFirebaseAnalytics();
};

#endif // GODOTX_FIREBASE_ANALYTICS_H

