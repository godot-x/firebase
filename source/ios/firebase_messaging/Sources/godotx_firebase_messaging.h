#ifndef GODOTX_FIREBASE_MESSAGING_H
#define GODOTX_FIREBASE_MESSAGING_H

#include "core/object/class_db.h"

class GodotxFirebaseMessaging : public Object {
    GDCLASS(GodotxFirebaseMessaging, Object);
    
protected:
    static void _bind_methods();
    
public:
    static GodotxFirebaseMessaging* instance;
    static GodotxFirebaseMessaging* get_singleton();

    void initialize();
    void request_permission();
    void get_token();
    void get_apns_token();
    void attempt_get_fcm_token();
    void subscribe_to_topic(String topic);
    void unsubscribe_from_topic(String topic);

    GodotxFirebaseMessaging();
    ~GodotxFirebaseMessaging();
};

#endif // GODOTX_FIREBASE_MESSAGING_H

