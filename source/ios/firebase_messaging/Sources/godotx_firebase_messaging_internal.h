#ifndef GODOTX_FIREBASE_MESSAGING_INTERNAL_H
#define GODOTX_FIREBASE_MESSAGING_INTERNAL_H

#import <Foundation/Foundation.h>
#include "core/variant/variant.h"
#include "core/variant/dictionary.h"

// Internal helper functions for converting Objective-C types to Godot types.
// These are only for use within .mm (Objective-C++) files.
Variant ns_object_to_variant(id val);
Dictionary user_info_to_dictionary(NSDictionary *userInfo);

#endif // GODOTX_FIREBASE_MESSAGING_INTERNAL_H
