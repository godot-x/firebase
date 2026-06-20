#include "godotx_firebase_remote_config_module.h"
#include "godotx_firebase_remote_config.h"

#include "core/config/engine.h"
#include "core/object/class_db.h"

GodotxFirebaseRemoteConfig *godotx_firebase_remote_config = nullptr;

void initialize_godotx_firebase_remote_config_module() {
    godotx_firebase_remote_config = memnew(GodotxFirebaseRemoteConfig);
    Engine::get_singleton()->add_singleton(Engine::Singleton("GodotxFirebaseRemoteConfig", godotx_firebase_remote_config));
}

void uninitialize_godotx_firebase_remote_config_module() {
    if (godotx_firebase_remote_config) {
        memdelete(godotx_firebase_remote_config);
        godotx_firebase_remote_config = nullptr;
    }
}
