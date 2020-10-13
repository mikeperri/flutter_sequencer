#include <vector>
#include <stdlib.h>
#include "CallbackManager.h"

Dart_PostCObjectType dartPostCObject = NULL;

void RegisterDart_PostCObject(Dart_PostCObjectType _dartPostCObject) {
    dartPostCObject = _dartPostCObject;
}

void callbackToDartBool(Dart_Port callback_port, bool value) {
    if (dartPostCObject == NULL) return;
    
    Dart_CObject dart_object;
    dart_object.type = Dart_CObject_kBool;
    dart_object.value.as_bool = value;
    
    bool result = dartPostCObject(callback_port, &dart_object);
    if (!result) {
        printf("call from native to Dart failed, result was: %d\n", result);
    }
}

void callbackToDartInt32(Dart_Port callback_port, int32_t value) {
    if (dartPostCObject == NULL) return;
    
    Dart_CObject dart_object;
    dart_object.type = Dart_CObject_kInt32;
    dart_object.value.as_int32 = value;
    
    bool result = dartPostCObject(callback_port, &dart_object);
    if (!result) {
        printf("call from native to Dart failed, result was: %d\n", result);
    }
}

void callbackToDartInt32Array(Dart_Port callbackPort, int length, int32_t* values) {
    if (dartPostCObject == NULL) return;

    Dart_CObject *valueObjects[length];
    int i;
    for (i = 0; i < length; ++i) {
        auto valueObject = new Dart_CObject;
        valueObject->type = Dart_CObject_kInt32;
        valueObject->value.as_int32 = values[i];

        valueObjects[i] = valueObject;
    }

    Dart_CObject dart_object;
    dart_object.type = Dart_CObject_kArray;
    dart_object.value.as_array.length = length;
    dart_object.value.as_array.values = valueObjects;

    bool result = dartPostCObject(callbackPort, &dart_object);
    if (!result) {
        printf("call from native to Dart failed, result was: %d\n", result);
    }

    for (i = 0; i < length; i++) {
        delete valueObjects[i];
    }
}

void callbackToDartStrArray(Dart_Port callbackPort, int length, char** values) {
    if (dartPostCObject == NULL) return;
    
    Dart_CObject **valueObjects = new Dart_CObject *[length];
    int i;
    for (i = 0; i < length; i++) {
        Dart_CObject *valueObject = new Dart_CObject;
        valueObject->type = Dart_CObject_kString;
        valueObject->value.as_string = values[i];
        
        valueObjects[i] = valueObject;
    }
    
    Dart_CObject dart_object;
    dart_object.type = Dart_CObject_kArray;
    dart_object.value.as_array.length = length;
    dart_object.value.as_array.values = valueObjects;
    
    bool result = dartPostCObject(callbackPort, &dart_object);
    if (!result) {
        printf("call from native to Dart failed, result was: %d\n", result);
    }

    for (i = 0; i < length; i++) {
        delete valueObjects[i];
    }
    delete[] valueObjects;
}
