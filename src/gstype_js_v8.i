/*
   Copyright (c) 2017 TOSHIBA Digital Solutions Corporation.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

#define BYTE_MIN -128
#define BYTE_MAX 127
#define SHORT_MIN -32768
#define SHORT_MAX 32767
#define UTC_TIMESTAMP_MAX 253402300799.999

%{
#include <ctime>
#include <limits>
%}

// rename all method to camel cases
%rename("%(lowercamelcase)s", %$isfunction) "";
/*
 * ignore unnecessary functions
 */
%ignore griddb::Row;
%ignore griddb::Container::getGSTypeList;
%ignore griddb::Container::getColumnCount;
%ignore griddb::RowSet::next_row;
%ignore griddb::RowSet::get_next_query_analysis;
%ignore griddb::RowSet::get_next_aggregation;
%ignore griddb::ContainerInfo::ContainerInfo(GSContainerInfo* containerInfo);

/*
 * Use attribute in Nodejs
 */
%include <attribute.i>

//Read only attribute Container::type
%attribute(griddb::Container, int, type, get_type);
//Read only attribute GSException::is_timeout 
%attribute(griddb::GSException, bool, isTimeout, is_timeout);
//Read only attribute PartitionController::partition_count 
%attribute(griddb::PartitionController, int, partitionCount, get_partition_count);
//Read only attribute RowKeyPredicate::partition_count 
%attribute(griddb::RowKeyPredicate, GSType, keyType, get_key_type);
//Read only attribute RowSet::size 
%attribute(griddb::RowSet, int32_t, size, size);
//Read only attribute RowSet::type 
%attribute(griddb::RowSet, GSRowSetType, type, type);
//Read only attribute Store::partition_info 
%attribute(griddb::Store, griddb::PartitionController*, partitionInfo, partition_info);
//Read only attribute ContainerInfo::name 
%attribute(griddb::ContainerInfo, GSChar*, name, get_name, set_name);
//Read only attribute ContainerInfo::type 
%attribute(griddb::ContainerInfo, GSContainerType, type, get_type, set_type);
//Read only attribute ContainerInfo::rowKeyAssign 
%attribute(griddb::ContainerInfo, bool, rowKey, get_row_key_assigned, set_row_key_assigned);
//Read only attribute ContainerInfo::columnInfoList 
%attributeval(griddb::ContainerInfo, ColumnInfoList, columnInfoList, get_column_info_list, set_column_info_list);
//Read only attribute ContainerInfo::columnInfoList 
%attributeval(griddb::ContainerInfo, griddb::ExpirationInfo, expiration, get_expiration_info, set_expiration_info);
//Read only attribute ExpirationInfo::time 
%attribute(griddb::ExpirationInfo, int, time, get_time, set_time);
//Read only attribute ExpirationInfo::unit 
%attribute(griddb::ExpirationInfo, GSTimeUnit, unit, get_time_unit, set_time_unit);
//Read only attribute ExpirationInfo::divisionCount 
%attribute(griddb::ExpirationInfo, int, divisionCount, get_division_count, set_division_count);

/*
 * Typemaps for catch GSException
 */
%typemap(throws) griddb::GSException %{
    SWIGV8_THROW_EXCEPTION(SWIG_V8_NewPointerObj(SWIG_as_voidptr(new griddb::GSException(&$1)), $descriptor(griddb::GSException *), SWIG_POINTER_OWN));
%}

/*
* fragment to support converting data for GSRow
*/
%fragment("convertFieldToObject", "header") {
static v8::Handle<v8::Value> convertFieldToObject(griddb::Field &field) {
    int listSize, i;
    void* arrayPtr;
    v8::Local<v8::Array> vals;
    switch (field.type) {
    case GS_TYPE_BLOB:
        return SWIGV8_STRING_NEW2((GSChar *)field.value.asBlob.data, field.value.asBlob.size);
    case GS_TYPE_BOOL:
        return SWIGV8_BOOLEAN_NEW((bool)field.value.asBool);
    case GS_TYPE_INTEGER:
        return SWIGV8_INT32_NEW(field.value.asInteger);
    case GS_TYPE_BYTE:
        return SWIGV8_INT32_NEW(field.value.asByte);
    case GS_TYPE_SHORT:
        return SWIGV8_INT32_NEW(field.value.asShort);
    case GS_TYPE_LONG:
        return SWIGV8_NUMBER_NEW(field.value.asLong);
    case GS_TYPE_FLOAT:
        return SWIGV8_NUMBER_NEW(field.value.asFloat);
    case GS_TYPE_DOUBLE:
        return SWIGV8_NUMBER_NEW(field.value.asDouble);
    case GS_TYPE_STRING:
        return SWIGV8_STRING_NEW(field.value.asString);
    case GS_TYPE_TIMESTAMP:
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
        return v8::Date::New(field.value.asTimestamp);
%#else
        return v8::Date::New(v8::Isolate::GetCurrent(), field.value.asTimestamp);
%#endif
%#if GS_COMPATIBILITY_SUPPORT_3_5
    case GS_TYPE_NULL:
        return SWIGV8_NULL();
%#endif
    case GS_TYPE_INTEGER_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
        listSize = field.value.asIntegerArray.size;
        arrayPtr = (void*) field.value.asIntegerArray.elements;
%#else
        listSize = field.value.asArray.length;
        arrayPtr = (void*) field.value.asArray.elements.asInteger;
%#endif

        vals = SWIGV8_ARRAY_NEW();
        for (i = 0; i < listSize; i++) {
            vals->Set(i, SWIG_From_int(*((int32_t *)arrayPtr + i)));
        }
        return vals;

    case GS_TYPE_STRING_ARRAY:
        GSChar** arrString;
%#if GS_COMPATIBILITY_VALUE_1_1_106
        listSize = field.value.asStringArray.size;
        arrString = (GSChar**) field.value.asStringArray.elements;
%#else
        listSize = field.value.asArray.length;
        arrString = (GSChar**) field.value.asArray.elements.asString;
%#endif
        vals = SWIGV8_ARRAY_NEW();
        for (i = 0; i < listSize; i++) {
            vals->Set(i, SWIGV8_STRING_NEW(((GSChar **)arrString)[i]));
        }
        return vals;

    case GS_TYPE_BOOL_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
        listSize = field.value.asBoolArray.size;
        arrayPtr = (void*) field.value.asBoolArray.elements;
%#else
        listSize = field.value.asArray.length;
        arrayPtr = (void*) field.value.asArray.elements.asBool;
%#endif
        vals = SWIGV8_ARRAY_NEW();
        for (i = 0; i < listSize; i++) {
            vals->Set(i, SWIG_From_bool(*((bool *)arrayPtr + i)));
        }
        return vals;
    case GS_TYPE_BYTE_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
        listSize = field.value.asByteArray.size;
        arrayPtr = (void*) field.value.asByteArray.elements;
%#else
        listSize = field.value.asArray.length;
        arrayPtr = (void*) field.value.asArray.elements.asByte;
%#endif
        vals = SWIGV8_ARRAY_NEW();
        for (i = 0; i < listSize; i++) {
            vals->Set(i, SWIG_From_int(*((int8_t *)arrayPtr + i)));
        }
        return vals;
    case GS_TYPE_SHORT_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
        listSize = field.value.asShortArray.size;
        arrayPtr = (void*) field.value.asShortArray.elements;
%#else
        listSize = field.value.asArray.length;
        arrayPtr = (void*) field.value.asArray.elements.asShort;
%#endif
        vals = SWIGV8_ARRAY_NEW();
        for (i = 0; i < listSize; i++) {
            vals->Set(i, SWIG_From_int(*((int16_t *)arrayPtr + i)));
        }
        return vals;
    case GS_TYPE_LONG_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
        listSize = field.value.asLongArray.size;
        arrayPtr = (void*) field.value.asLongArray.elements;
%#else
        listSize = field.value.asArray.length;
        arrayPtr = (void*) field.value.asArray.elements.asLong;
%#endif
        vals = SWIGV8_ARRAY_NEW();
        for (i = 0; i < listSize; i++) {
            vals->Set(i, SWIGV8_NUMBER_NEW(((int64_t *)arrayPtr)[i]));
        }
        return vals;
    case GS_TYPE_FLOAT_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
        listSize = field.value.asFloatArray.size;
        arrayPtr = (void*) field.value.asFloatArray.elements;
%#else
        listSize = field.value.asArray.length;
        arrayPtr = (void*) field.value.asArray.elements.asFloat;
%#endif
        vals = SWIGV8_ARRAY_NEW();
        for (i = 0; i < listSize; i++) {
            vals->Set(i, SWIGV8_NUMBER_NEW(((float *)arrayPtr)[i]));
        }
        return vals;
    case GS_TYPE_DOUBLE_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
        listSize = field.value.asDoubleArray.size;
        arrayPtr = (void*) field.value.asDoubleArray.elements;
%#else
        listSize = field.value.asArray.length;
        arrayPtr = (void*) field.value.asArray.elements.asDouble;
%#endif
        vals = SWIGV8_ARRAY_NEW();
        for (i = 0; i < listSize; i++) {
            vals->Set(i, SWIGV8_NUMBER_NEW(((double *)arrayPtr)[i]));
        }
        return vals;
    case GS_TYPE_TIMESTAMP_ARRAY:

%#if GS_COMPATIBILITY_VALUE_1_1_106
        listSize = field.value.asTimestampArray.size;
        arrayPtr = (void*) field.value.asTimestampArray.elements;
%#else
        listSize = field.value.asArray.length;
        arrayPtr = (void*) field.value.asArray.elements.asTimestamp;
%#endif
        vals = SWIGV8_ARRAY_NEW();
        for (i = 0; i < listSize; i++) {
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
            vals->Set(i, v8::Date::New(((GSTimestamp *)arrayPtr)[i]));
%#else
            vals->Set(i, v8::Date::New(v8::Isolate::GetCurrent(), ((GSTimestamp *)arrayPtr)[i]));
%#endif
        }
        return vals;
    default:
        return SWIGV8_NULL();
    }

    return SWIGV8_NULL();
}
}

%fragment("convertGSRowFieldToObject", "header",
        fragment = "convertTimestampToObject") {
static v8::Handle<v8::Value> convertGSRowFieldToObject(GSRow *row, int column, bool timestamp_to_float = true) {

    size_t size;
    const int8_t *byteArrVal;
    const int16_t *shortArrVal;
    const int32_t *intArrVal;
    const int64_t *longArrVal;
    const double *doubleArrVal;
    const float *floatArrVal;
    const GSChar *const *stringArrVal;
    const GSBool *boolArrVal;
    const GSTimestamp *timestampArrVal;
    v8::Local<v8::Array> list;
    int i;

    GSValue mValue;
    GSType mType;
    GSResult ret = gsGetRowFieldGeneral(row, column, &mValue, &mType);
    switch (mType) {
        case GS_TYPE_LONG:
            return SWIGV8_NUMBER_NEW(mValue.asLong);
        case GS_TYPE_STRING:
            return SWIGV8_STRING_NEW(mValue.asString);
%#if GS_COMPATIBILITY_SUPPORT_3_5
        case GS_TYPE_NULL:
            return SWIGV8_NULL();
%#endif
        case GS_TYPE_BLOB:
            return SWIGV8_STRING_NEW2((GSChar *)mValue.asBlob.data, mValue.asBlob.size);
        case GS_TYPE_BOOL:
            return SWIGV8_BOOLEAN_NEW((bool)mValue.asBool);
        case GS_TYPE_INTEGER:
            return SWIGV8_INT32_NEW(mValue.asInteger);
        case GS_TYPE_FLOAT:
            return SWIGV8_NUMBER_NEW(mValue.asFloat);
        case GS_TYPE_DOUBLE:
            return SWIGV8_NUMBER_NEW(mValue.asDouble);
        case GS_TYPE_TIMESTAMP:
            return convertTimestampToObject(&mValue.asTimestamp, timestamp_to_float);
        case GS_TYPE_BYTE:
            return SWIGV8_INT32_NEW(mValue.asByte);
        case GS_TYPE_SHORT:
            return SWIGV8_INT32_NEW(mValue.asShort);
        case GS_TYPE_INTEGER_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = mValue.asIntegerArray.size;
            intArrVal = mValue.asIntegerArray.elements;
%#else
            size = mValue.asArray.length;
            intArrVal = mValue.asArray.elements.asInteger;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIG_From_int(intArrVal[i]));
            }
            return list;
        case GS_TYPE_STRING_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = mValue.asStringArray.size;
            stringArrVal = mValue.asStringArray.elements;
%#else
            size = mValue.asArray.length;
            stringArrVal = mValue.asArray.elements.asString;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIGV8_STRING_NEW(((GSChar **)stringArrVal)[i]));
            }
            return list;
        case GS_TYPE_BOOL_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = mValue.asBoolArray.size;
            boolArrVal = field.value.asBoolArray.elements;
%#else
            size = mValue.asArray.length;
            boolArrVal = mValue.asArray.elements.asBool;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIG_From_bool(boolArrVal[i]));
            }
            return list;
        case GS_TYPE_BYTE_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = mValue.asByteArray.size;
            byteArrVal = mValue.asByteArray.elements;
%#else
            size = mValue.asArray.length;
            byteArrVal = mValue.asArray.elements.asByte;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIG_From_int(byteArrVal[i]));
            }
            return list;
        case GS_TYPE_SHORT_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = mValue.asShortArray.size;
            shortArrVal = mValue.asShortArray.elements;
%#else
            size = mValue.asArray.length;
            shortArrVal = mValue.asArray.elements.asShort;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIG_From_int(shortArrVal[i]));
            }
            return list;
        case GS_TYPE_LONG_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = mValue.asLongArray.size;
            longArrVal = mValue.asLongArray.elements;
%#else
            size = mValue.asArray.length;
            longArrVal = mValue.asArray.elements.asLong;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIGV8_NUMBER_NEW(longArrVal[i]));
            }
            return list;
        case GS_TYPE_FLOAT_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = mValue.asFloatArray.size;
            floatArrVal = mValue.asFloatArray.elements;
%#else
            size = mValue.asArray.length;
            floatArrVal = mValue.asArray.elements.asFloat;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIGV8_NUMBER_NEW(((float *)floatArrVal)[i]));
            }
            return list;
        case GS_TYPE_DOUBLE_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = mValue.asDoubleArray.size;
            doubleArrVal = mValue.asDoubleArray.elements;
%#else
            size = mValue.asArray.length;
            doubleArrVal = mValue.asArray.elements.asDouble;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIGV8_NUMBER_NEW(((double *)doubleArrVal)[i]));
            }
            return list;
        case GS_TYPE_TIMESTAMP_ARRAY:
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = mValue.asTimestampArray.size;
            timestampArrVal = mValue.asTimestampArray.elements;
%#else
            size = mValue.asArray.length;
            timestampArrVal = mValue.asArray.elements.asTimestamp;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, convertTimestampToObject((GSTimestamp*)&(timestampArrVal[i]), timestamp_to_float));
            }
            return list;
        case GS_TYPE_GEOMETRY:
            return SWIGV8_STRING_NEW(mValue.asGeometry);
        default:
            return SWIGV8_NULL();
    }

    return SWIGV8_NULL();
}
}


%fragment("cleanStringArray", "header") {
static void cleanStringArray(GSChar** arrString, size_t size) {
    if (!arrString) {
        return;
    }

    for (int i = 0; i < size; i++) {
        if (arrString[i]) {
            free((void*)arrString[i]);
        }
    }

    free(arrString);
}
}

%fragment("convertObjectToStringArray", "header",
        fragment = "cleanStringArray") {
static GSChar** convertObjectToStringArray(v8::Local<v8::Value> value, int* size) {
    GSChar** arrString = NULL;
    size_t arraySize;
    int alloc = 0;
    char* v;
    v8::Local<v8::Array> arr;
    if(!value->IsArray()) {
        return NULL;
    }
    arr = v8::Local<v8::Array>::Cast(value);
    arraySize = (int) arr->Length();

    *size = (int)arraySize;
    arrString = (GSChar**)malloc(arraySize * sizeof(GSChar*));
    if (arrString == NULL) {
        return NULL;
    }

    memset(arrString, 0x0, arraySize * sizeof(GSChar*));
    for (int i = 0; i < arraySize; i++) {
        if (!arr->Get(i)->IsString()) {
            cleanStringArray(arrString, arraySize);
            return NULL;
        }
        
        int res = SWIG_AsCharPtrAndSize(arr->Get(i), &v, NULL, &alloc);
        if (!SWIG_IsOK(res)) {
            cleanStringArray(arrString, arraySize);
            return NULL;
        }

        arrString[i] = strdup(v);

        if (alloc != SWIG_OLDOBJ) {
            %delete_array(v);
        }
    }

    return arrString;
}
}

/**
 * Support convert type from object to Bool. input in target language can be :
 * integer or boolean
 */
%fragment("convertObjectToBool", "header", fragment = "SWIG_AsVal_bool", fragment = "SWIG_AsVal_int") {
static bool convertObjectToBool(v8::Local<v8::Value> value, bool* boolValPtr) {
    int checkConvert = 0;
    if (value->IsInt32()) {
        //input can be integer
        int intVal ;
        checkConvert = SWIG_AsVal_int(value, &intVal);
        if (!SWIG_IsOK(checkConvert)) {
            return false;
        }
        *boolValPtr = (intVal != 0);
        return true;
    } else {
        //input is boolean
        checkConvert = SWIG_AsVal_bool(value, boolValPtr);
        if (!SWIG_IsOK(checkConvert)) {
            return false;
        }
        return true;
    }
}
}

/**
 * Support compare double
 */
%fragment("double_equals", "header") {
bool double_equals(double a, double b, double epsilon){
    return fabs(a - b) < epsilon;
}
}

%fragment("convertTimestampToObject", "header") {
static v8::Handle<v8::Value> convertTimestampToObject(GSTimestamp* timestamp, bool timestamp_to_float = true) {
    if (timestamp_to_float) {
        return SWIGV8_NUMBER_NEW(*timestamp);
    }

%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
    return v8::Date::New(*timestamp);
%#else
    return v8::Date::New(v8::Isolate::GetCurrent(), *timestamp);
%#endif
}
}

/**
 * Support convert type from object to Float. input in target language can be :
 * float or integer
 */
%fragment("convertObjectToDouble", "header") {
static bool convertObjectToDouble(v8::Local<v8::Value> value, double* floatValPtr) {
    int checkConvert = 0;
    if (value->IsInt32()) {
        //input can be integer
        long int intVal;
        checkConvert = SWIG_AsVal_long(value, &intVal);
        if (!SWIG_IsOK(checkConvert)) {
            return false;
        }
        *floatValPtr = intVal;
        //When input value is integer, it should be between -9007199254740992(-2^53)/9007199254740992(2^53).
        return (-9007199254740992 <= intVal && 9007199254740992 >= intVal);
    } else {
        //input is float
        if (!(value->IsNumber())) {
            return false;
        }
        *floatValPtr = value->NumberValue();
        return true;
    }
}
}
/**
 * Support convert type from object to Float. input in target language can be :
 * float or integer
 */
%fragment("convertObjectToFloat", "header", fragment = "double_equals") {
static bool convertObjectToFloat(v8::Local<v8::Value> value, float* floatValPtr) {
    int checkConvert = 0;

    if (value->IsInt32()) {
        //input can be integer
        long int intVal;
        checkConvert = SWIG_AsVal_long(value, &intVal);
        if (!SWIG_IsOK(checkConvert)) {
            return false;
        }
        *floatValPtr = intVal;
        //When input value is integer, it should be between -16777216(-2^24)/16777216(2^24).
        return (-16777216 <= intVal && 16777216 >= intVal);

    } else {
        //input is float
        if (!(value->IsNumber())) {
            return false;
        }
        *floatValPtr = value->NumberValue();

        if (double_equals(*floatValPtr, std::numeric_limits<float>::min(), std::numeric_limits<float>::epsilon()) ||
                 double_equals(*floatValPtr, std::numeric_limits<float>::max(), std::numeric_limits<float>::epsilon()) ||
                 double_equals(*floatValPtr, (-1) * std::numeric_limits<float>::max(), std::numeric_limits<float>::epsilon()) ||
                 double_equals(*floatValPtr, (-1) * std::numeric_limits<float>::min(), std::numeric_limits<float>::epsilon())) {
             return true;
         }
         return ((*floatValPtr > std::numeric_limits<float>::min() &&
                 *floatValPtr < std::numeric_limits<float>::max())|| (*floatValPtr > (-1)*std::numeric_limits<float>::max() &&
                 *floatValPtr < (-1) * std::numeric_limits<float>::min()));
    }
}
}
/**
 * Support convert type from object to GSTimestamp: input in target language can be :
 * datetime object, string or float
 */
%fragment("convertObjectToGSTimestamp", "header", fragment = "convertObjectToFloat") {
static bool convertObjectToGSTimestamp(v8::Local<v8::Value> value, GSTimestamp* timestamp) {
    int year, month, day, hour, minute, second, milliSecond, microSecond;
    size_t size = 0;
    int res;
    char* v = 0;
    bool vbool;
    int alloc;
    char s[30];
    GSBool retConvertTimestamp;

    if (value->IsBoolean()) {
        return false;
    }
    float floatTimestamp;
    double utcTimestamp;
    if (value->IsDate()) {
        *timestamp = value->NumberValue();
        return true;
    } else if (value->IsString()) {

        // Input is datetime string: ex
        res = SWIG_AsCharPtrAndSize(value, &v, &size, &alloc);

        if (!SWIG_IsOK(res)) {
           return false;
        }
        // error when string len is too short
        if (strlen(v) < 19) {
            if (alloc != SWIG_OLDOBJ) {
                delete [] v;
            }
            return false;
        }
        // this is for convert python's string datetime (YYYY-MM-DDTHH:mm:ss:sssZ)
        // to griddb's string datetime (YYYY-MM-DDTHH:mm:ss.sssZ)
        v[19] = '.';

        retConvertTimestamp = gsParseTime(v, timestamp);
        if (alloc != SWIG_OLDOBJ) {
            delete [] v;
        }

        return (retConvertTimestamp == GS_TRUE);
    } else if (value->IsNumber()) {
        *timestamp = value->NumberValue();
        if (utcTimestamp > UTC_TIMESTAMP_MAX) {
            return false;
        }
        return true;
    } else {
        // Invalid input
        return false;
    }
}
}

/**
 * Support covert Field from Nodejs object to C Object with specific type
 */
%fragment("convertObjectToFieldWithType", "header", fragment = "SWIG_AsCharPtrAndSize"
        , fragment = "convertObjectToBool", fragment = "convertObjectToGSTimestamp"
        ,fragment = "convertObjectToDouble"
        , fragment = "convertObjectToStringArray") {
    static bool convertObjectToFieldWithType(griddb::Field &field, v8::Local<v8::Value> value, GSType type) {
        size_t size = 0;
        int res;
        char* v = 0;
        bool vbool;
        int *alloc = (int*) malloc(sizeof(int));
        if(alloc == NULL) {
            return false;
        }
        memset(alloc, 0, sizeof(int));

        field.type = type;
        if (value->IsNull() || value->IsUndefined()) {
%#if GS_COMPATIBILITY_SUPPORT_3_5
            field.type = GS_TYPE_NULL;
            return true;
%#else
			return false;
%#endif
        }
        GSChar *mydata;
        void *blobData;
        int year, month, day, hour, minute, second, milliSecond;
        char s[30];
        int checkConvert = 0;
        GSBool retConvertTimestamp;
        GSChar** arrString = NULL;
        int arraySize, i;
        void* arrayPtr;
        int tmpInt;
        v8::Local<v8::Array> arr;
        double tmpDouble; //support convert to double, double array
        float tmpFloat; //support convert to float, float array
        int32_t *intArr;
        GSBool *boolArr;
        int8_t* byteArr;
        int16_t* shortArr;
        int64_t* longArr;
        float* floatArr;
        double* doubleArr;
        GSTimestamp* timestampArr;
        int fixSize;
        switch(type) {
            case (GS_TYPE_STRING):
                if (!value->IsString()) {
                    return false;
                }
                res = SWIG_AsCharPtrAndSize(value, &v, &size, alloc);
                if (!SWIG_IsOK(res)) {
                   return false;
                }
                mydata = (GSChar*)malloc(sizeof(GSChar) * size + 1);
                memset(mydata, 0x0, sizeof(GSChar) * size + 1);
                memcpy(mydata, v, size);
                field.value.asString = mydata;
                field.type = GS_TYPE_STRING;
                break;

            case (GS_TYPE_BOOL):
                vbool = convertObjectToBool(value, (bool*) &field.value.asBool);
                if (!vbool) {
                    return false;
                }
                break;

            case (GS_TYPE_BYTE):
                if (!value->IsInt32()) {
                    return false;
                }
                if (value->IntegerValue() < BYTE_MIN || value->IntegerValue() > BYTE_MAX) {
                    return false;
                }
                field.value.asByte = value->IntegerValue();
                break;

            case (GS_TYPE_SHORT):
                if (!value->IsInt32()) {
                    return false;
                }
                if (value->IntegerValue() < SHORT_MIN || value->IntegerValue() > SHORT_MAX) {
                    return false;
                }
                field.value.asShort = value->IntegerValue();
                break;

            case (GS_TYPE_INTEGER):
                if (!value->IsInt32()) {
                    return false;
                }
                field.value.asInteger = value->IntegerValue();
                break;

            case (GS_TYPE_LONG):
                checkConvert = SWIG_AsVal_long(value, &field.value.asLong);
                if (!SWIG_IsOK(checkConvert)) {
                    return false;
                }
                break;

            case (GS_TYPE_FLOAT):
                    vbool = convertObjectToFloat(value, &tmpFloat);
                    if (!vbool) {
                        return false;
                    }
                    field.value.asFloat = tmpFloat;
                break;

            case (GS_TYPE_DOUBLE):
                    vbool = convertObjectToDouble(value, &tmpDouble);
                    if (!vbool) {
                        return false;
                    }
                    field.value.asDouble = tmpDouble;
                break;

            case (GS_TYPE_TIMESTAMP):
                return convertObjectToGSTimestamp(value, &field.value.asTimestamp);
                break;
            case (GS_TYPE_BLOB):
                if(!value->IsString()) {
                    return false;
                }
                res = SWIG_AsCharPtrAndSize(value, &v, &size, alloc);
                if (!SWIG_IsOK(res)) {
                   return false;
                }
                fixSize = size - 1;
                mydata = (GSChar*)malloc(sizeof(GSChar) * fixSize);
                memcpy(mydata, v, fixSize);
                field.value.asBlob.data = mydata;
                field.value.asBlob.size = fixSize;
                break;
            case (GS_TYPE_INTEGER_ARRAY):
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                arraySize = (int) arr->Length();
                arrayPtr = NULL;
                intArr = (int32_t *) malloc(arraySize * sizeof(int32_t));
                if (intArr == NULL) {
                    return false;
                }
%#if GS_COMPATIBILITY_VALUE_1_1_106
                field.value.asIntegerArray.size = arraySize;
                field.value.asIntegerArray.elements = (const int32_t *) intArr;
%#else
                field.value.asArray.length = arraySize;
                field.value.asArray.elements.asInteger = (const int32_t *) intArr;
%#endif
                for (i = 0; i < arraySize; i++) {
                    checkConvert = SWIG_AsVal_int(arr->Get(i), (intArr + i));
                    if (!SWIG_IsOK(checkConvert)) {
                        free((void*)intArr);
%#if GS_COMPATIBILITY_VALUE_1_1_106
                        field.value.asIntegerArray.elements = NULL;
%#else
                        field.value.asArray.elements.asInteger = NULL;
%#endif
                        return false;
                    }
                }
                break;
            case (GS_TYPE_GEOMETRY):
                return false;
                break;
            case (GS_TYPE_STRING_ARRAY):
                arrString = convertObjectToStringArray(value, &arraySize);
                if (!arrString) {
                    return false;
                }
%#if GS_COMPATIBILITY_VALUE_1_1_106
                field.value.asStringArray.size = arraySize;
                field.value.asStringArray.elements = arrString;
%#else
                field.value.asArray.length = arraySize;
                field.value.asArray.elements.asString = arrString;
%#endif
                break;
            case (GS_TYPE_BOOL_ARRAY):
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                arraySize = (int) arr->Length();
                arrayPtr = NULL;
                boolArr = (GSBool *) malloc(arraySize * sizeof(GSBool));
                if (boolArr == NULL) {
                    return false;
                }
%#if GS_COMPATIBILITY_VALUE_1_1_106
                field.value.asBoolArray.size = arraySize;
                field.value.asBoolArray.elements = (const GSBool *) boolArr;
%#else
                field.value.asArray.length = arraySize;
                field.value.asArray.elements.asBool = (const GSBool *) boolArr;
%#endif
                for (i = 0; i < arraySize; i++) {
                    vbool = convertObjectToBool(arr->Get(i), (bool*)(boolArr + i));
                    if (!vbool) {
                        free((void*)boolArr);
%#if GS_COMPATIBILITY_VALUE_1_1_106
                        field.value.asBoolArray.elements = NULL:
%#else
                        field.value.asArray.elements.asBool = NULL;
%#endif
                        return false;
                    }
                }
                break;
            case (GS_TYPE_BYTE_ARRAY):
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                arraySize = (int) arr->Length();
                arrayPtr = NULL;
                byteArr = (int8_t *) malloc(arraySize * sizeof(int8_t));
                if (byteArr == NULL) {
                    return false;
                }
%#if GS_COMPATIBILITY_VALUE_1_1_106
                field.value.asByteArray.size = arraySize;
                field.value.asByteArray.elements = (const int8_t *) byteArr;
%#else
                field.value.asArray.length = arraySize;
                field.value.asArray.elements.asByte = (const int8_t *) byteArr;
%#endif
                for (i = 0; i < arraySize; i++) {

                    checkConvert = SWIG_AsVal_int(arr->Get(i), &tmpInt);
                    byteArr[i] = (int8_t)tmpInt;
                     if (!SWIG_IsOK(checkConvert) ||
                        tmpInt < std::numeric_limits<int8_t>::min() ||
                        tmpInt > std::numeric_limits<int8_t>::max()) {
                         free((void*)byteArr);
%#if GS_COMPATIBILITY_VALUE_1_1_106
                        field.value.asByteArray.elements = NULL;
%#else
                        field.value.asArray.elements.asByte = NULL;
%#endif
                        return false;
                    }
                }
                break;
            case (GS_TYPE_SHORT_ARRAY):
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                arraySize = (int) arr->Length();
                arrayPtr = NULL;
                shortArr = (int16_t *) malloc(arraySize * sizeof(int16_t));
                if (shortArr == NULL) {
                    return false;
                }
%#if GS_COMPATIBILITY_VALUE_1_1_106
                field.value.asShortArray.size = arraySize;
                field.value.asShortArray.elements = (const int16_t *) shortArr;
%#else
                field.value.asArray.length = arraySize;
                field.value.asArray.elements.asShort = shortArr;
%#endif
                for (i = 0; i < arraySize; i++) {
                    checkConvert = SWIG_AsVal_int(arr->Get(i), &tmpInt);
                    shortArr[i] = (int16_t)tmpInt;
                    if (!SWIG_IsOK(checkConvert) ||
                        tmpInt < std::numeric_limits<int16_t>::min() ||
                        tmpInt > std::numeric_limits<int16_t>::max()) {
                        free((void*)shortArr);
%#if GS_COMPATIBILITY_VALUE_1_1_106
                        field.value.asShortArray.elements = NULL;
%#else
                        field.value.asArray.elements.asShort = NULL;
%#endif
                        return false;
                    }
                }
                break;
            case (GS_TYPE_LONG_ARRAY):
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                arraySize = (int) arr->Length();
                arrayPtr = NULL;
                longArr = (int64_t *) malloc(arraySize * sizeof(int64_t));
                if (longArr == NULL) {
                    return false;
                }
%#if GS_COMPATIBILITY_VALUE_1_1_106
                field.value.asLongArray.size = arraySize;
                field.value.asLongArray.elements = (const int64_t *) longArr;
%#else
                field.value.asArray.length = arraySize;
                field.value.asArray.elements.asLong = longArr;
%#endif
                for (i = 0; i < arraySize; i++) {
                    checkConvert = SWIG_AsVal_long(arr->Get(i), ((int64_t *)longArr + i));
                    if (!SWIG_IsOK(checkConvert) ) {
                        free((void*) longArr);
%#if GS_COMPATIBILITY_VALUE_1_1_106
                        field.value.asLongArray.elements = NULL;
%#else
                        field.value.asArray.elements.asLong = NULL;
%#endif
                        return false;
                    }
                }
                break;
            case (GS_TYPE_FLOAT_ARRAY):
                float* floatPtr;
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                arraySize = (int) arr->Length();
                arrayPtr = NULL;
                floatArr = (float *) malloc(arraySize * sizeof(float));
                if (floatArr == NULL) {
                    return false;
                }
%#if GS_COMPATIBILITY_VALUE_1_1_106
                field.value.asFloatArray.size = arraySize;
                field.value.asFloatArray.elements = (const float *) floatArr;
%#else
                field.value.asArray.length = arraySize;
                field.value.asArray.elements.asFloat = floatArr;
%#endif

                for (i = 0; i < arraySize; i++) {
                    vbool = convertObjectToFloat(arr->Get(i), &tmpFloat);
                    floatPtr[i] = tmpFloat;
                    if (!vbool) {
                        free((void*)floatArr);
%#if GS_COMPATIBILITY_VALUE_1_1_106
                        field.value.asFloatArray.elements = NULL;
%#else
                        field.value.asArray.elements.asFloat = NULL;
%#endif
                        return false;
                    }
                }
                break;
            case (GS_TYPE_DOUBLE_ARRAY):
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                arraySize = (int) arr->Length();
                arrayPtr = NULL;
                doubleArr = (double *) malloc(arraySize * sizeof(double));
                if (doubleArr == NULL) {
                    return false;
                }
%#if GS_COMPATIBILITY_VALUE_1_1_106
                field.value.asDoubleArray.size = arraySize;
                field.value.asDoubleArray.elements = (const double *) doubleArr;
%#else
                field.value.asArray.length = arraySize;
                field.value.asArray.elements.asDouble = doubleArr;
%#endif
                for (i = 0; i < arraySize; i++) {
                    vbool = convertObjectToDouble(arr->Get(i), &tmpDouble);
                    doubleArr[i] = tmpDouble;
                    if (!vbool){
                        free((void*) doubleArr);
%#if GS_COMPATIBILITY_VALUE_1_1_106
                        field.value.asDoubleArray.elements = NULL;
%#else
                        field.value.asArray.elements.asDouble = NULL;
%#endif
                        return false;
                    }
                }
                break;
            case (GS_TYPE_TIMESTAMP_ARRAY):
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                arraySize = (int) arr->Length();
                arrayPtr = NULL;
                timestampArr = (GSTimestamp *) malloc(arraySize * sizeof(GSTimestamp));
%#if GS_COMPATIBILITY_VALUE_1_1_106
                field.value.asTimestampArray.size = arraySize;
                field.value.asTimestampArray.elements = timestampArr;
%#else
                field.value.asArray.length = arraySize;
                field.value.asArray.elements.asTimestamp = (const GSTimestamp *) timestampArr;
%#endif
                bool checkRet;
                for (i = 0; i < arraySize; i++) {
                    checkRet = convertObjectToGSTimestamp(arr->Get(i), (timestampArr + i));
                    if (!checkRet) {
                        free((void*)timestampArr);
%#if GS_COMPATIBILITY_VALUE_1_1_106
                        field.value.asTimestampArray.elements = NULL:
%#else
                        field.value.asArray.elements.asTimestamp = NULL;
%#endif
                        return false;
                    }
                }
            default:
                //Not support for now
                return false;
                break;
        }
        return true;
    }
}

%fragment("convertObjectToGSRowField", "header", fragment = "SWIG_AsCharPtrAndSize",
        fragment = "convertObjectToDouble", fragment = "convertObjectToGSTimestamp", 
        fragment = "SWIG_AsVal_bool", fragment = "convertObjectToBool", 
        fragment = "double_equals", fragment = "convertObjectToFloat", 
        fragment = "convertObjectToStringArray") {
    static bool convertObjectToGSRowField(GSRow *row, int column, v8::Local<v8::Value> value, GSType type) {
        int8_t byteVal;
        int16_t shortVal;
        int32_t intVal;
        int64_t longVal;
        float floatVal;
        double doubleVal;
        GSChar* stringVal;
        char* stringValChar;
        GSBlob blobVal;
        GSBool boolVal;
        GSTimestamp timestampVal;
        GSChar *geometryVal;

        size_t size;
        int8_t *byteArrVal;
        int16_t *shortArrVal;
        int32_t *intArrVal;
        int64_t *longArrVal;
        double *doubleArrVal;
        float *floatArrVal;
        const GSChar *const *stringArrVal;
        GSBool *boolArrVal;
        GSTimestamp *timestampArrVal;

        int tmpInt; //support convert 
        double tmpDouble; //support convert to double, double array
        float tmpFloat; //support convert to float, float array
        int res;
        char* v = 0;
        bool vbool;
        int alloc;
        int i, length;
        v8::Local<v8::Array> arr;
        GSResult ret;
        GSChar *mydata;

        if (value->IsNull() || value->IsUndefined()) {
%#if GS_COMPATIBILITY_SUPPORT_3_5
            ret = gsSetRowFieldNull(row, column); 
            return (ret == GS_RESULT_OK);
%#else
        //Not support NULL
        return false;
%#endif
        }

        int checkConvert = 0;
        switch(type) {
            case (GS_TYPE_STRING):
                if (!value->IsString()) {
                    return false;
                }
                res = SWIG_AsCharPtrAndSize(value, &stringValChar, &size, &alloc);
                if (!SWIG_IsOK(res)) {
                    return false;
                }
                stringVal = stringValChar;
                ret = gsSetRowFieldByString(row, column, stringVal);
                if (alloc == SWIG_NEWOBJ) {
                    %delete_array(stringValChar);
                }
                break;
            case (GS_TYPE_LONG):
                checkConvert = SWIG_AsVal_long(value, &longVal);
                if (!SWIG_IsOK(checkConvert)) {
                    return false;
                }
                ret = gsSetRowFieldByLong(row, column, longVal);
                break;
            case (GS_TYPE_BOOL):
                vbool = convertObjectToBool(value, (bool*)&boolVal);
                if (!vbool) {
                    return false;
                }
                ret = gsSetRowFieldByBool(row, column, boolVal);
                break;
            case (GS_TYPE_BYTE):
                if (!value->IsInt32()) {
                    return false;
                }
                if (value->IntegerValue() < std::numeric_limits<int8_t>::min() || value->IntegerValue() > std::numeric_limits<int8_t>::max()) {
                    return false;
                }
                ret = gsSetRowFieldByByte(row, column, value->IntegerValue());
                break;

            case (GS_TYPE_SHORT):
                if (!value->IsInt32()) {
                    return false;
                }
                if (value->IntegerValue() < std::numeric_limits<int16_t>::min() || 
                        value->IntegerValue() > std::numeric_limits<int16_t>::max()) {
                    return false;
                }
                ret = gsSetRowFieldByShort(row, column, value->IntegerValue());
                break;

            case (GS_TYPE_INTEGER):
                if (!value->IsInt32()) {
                    return false;
                }
                ret = gsSetRowFieldByInteger(row, column, value->IntegerValue());
                break;
            case (GS_TYPE_FLOAT):
                vbool = convertObjectToFloat(value, &floatVal);
                if (!vbool) {
                    return false;
                }
                ret = gsSetRowFieldByFloat(row, column, floatVal);
                break;
            case (GS_TYPE_DOUBLE):
                vbool = convertObjectToDouble(value, &doubleVal);
                if (!vbool) {
                    return false;
                }
                ret = gsSetRowFieldByDouble(row, column, doubleVal);
                break;
            case (GS_TYPE_TIMESTAMP):
                vbool = convertObjectToGSTimestamp(value, &timestampVal);
                if (!vbool) {
                    return false;
                }
                ret = gsSetRowFieldByTimestamp(row, column, timestampVal);
                break;
            case (GS_TYPE_BLOB):
                if(!value->IsString()) {
                    return false;
                }
                res = SWIG_AsCharPtrAndSize(value, &v, &size, &alloc);
                if (!SWIG_IsOK(res)) {
                   return false;
                }
                int fixSize;
                //Remove null character
                fixSize = size -1;
                mydata = (GSChar*)malloc(sizeof(GSChar) * fixSize);
                memcpy(mydata, v, fixSize);
                blobVal.data = mydata;
                blobVal.size = fixSize;
                ret = gsSetRowFieldByBlob(row, column, (const GSBlob *)&blobVal);
                if (mydata) {
                    free((void*)mydata);
                }
                if (alloc == SWIG_NEWOBJ) {
                    %delete_array(v);
                }
                break;
            case (GS_TYPE_STRING_ARRAY):
                stringArrVal = convertObjectToStringArray(value, &length);
                if (stringArrVal == NULL) {
                    return false;
                }
                size = length;
                ret = gsSetRowFieldByStringArray(row, column, stringArrVal, size);
                if (stringArrVal) {
                    for (i = 0; i < length; i++) {
                        if (stringArrVal[i]) {
                            free(const_cast<GSChar*> (stringArrVal[i]));
                        }
                    }
                    free(const_cast<GSChar**> (stringArrVal));
                }
                break;
            case (GS_TYPE_GEOMETRY):
                if (!value->IsString()) {
                 return false;
                }
                res = SWIG_AsCharPtrAndSize(value, &geometryVal, &size, &alloc);

                if (!SWIG_IsOK(res)) {
                    return false;
                }

                if (geometryVal && size) {
                    geometryVal = (alloc == SWIG_NEWOBJ) ? geometryVal : %new_copy_array(geometryVal, size, GSChar);
                }
                ret = gsSetRowFieldByGeometry(row, column, geometryVal);
                if (geometryVal) {
                    delete [] geometryVal;
                }
                break;
                    
            case (GS_TYPE_INTEGER_ARRAY):
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                size = (int) arr->Length();
                intArrVal = (int32_t *) malloc(size * sizeof(int32_t));
                if (intArrVal == NULL) {
                    return false;
                }
                for (i = 0; i < size; i++) {
                    checkConvert = SWIG_AsVal_int(arr->Get(i), (intArrVal + i));
                    if (!SWIG_IsOK(checkConvert)) {
                        free((void*)intArrVal);
                        intArrVal = NULL;
                        return false;
                    }
                }
                ret = gsSetRowFieldByIntegerArray(row, column, (const int32_t *) intArrVal, size);
                free ((void*) intArrVal);
                break;
            case GS_TYPE_BOOL_ARRAY:
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                size = (int) arr->Length();
                boolArrVal = (GSBool *) malloc(size * sizeof(GSBool));
                if (boolArrVal == NULL) {
                    return false;
                }
                for (i = 0; i < size; i++) {
                    vbool = convertObjectToBool(arr->Get(i), (bool*)(boolArrVal + i));
                    if (!vbool) {
                        free((void*)boolArrVal);
                        boolArrVal = NULL;
                        return false;
                    }
                }
                ret = gsSetRowFieldByBoolArray(row, column, (const GSBool *)boolArrVal, size);
                free ((void*) boolArrVal);
                break;
            case GS_TYPE_BYTE_ARRAY:
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                size = (int) arr->Length();
                byteArrVal = (int8_t *) malloc(size * sizeof(int8_t));
                if (byteArrVal == NULL) {
                    return false;
                }
                for (i = 0; i < size; i++) {
                    checkConvert = SWIG_AsVal_int(arr->Get(i), &tmpInt);
                    byteArrVal[i] = (int8_t)tmpInt;
                     if (!SWIG_IsOK(checkConvert) ||
                        tmpInt < std::numeric_limits<int8_t>::min() ||
                        tmpInt > std::numeric_limits<int8_t>::max() ||
                        (!arr->Get(i)->IsInt32())) {
                         free((void*)byteArrVal);
                         byteArrVal = NULL;
                         return false;
                    }
                }
                ret = gsSetRowFieldByByteArray(row, column, (const int8_t *)byteArrVal, size);
                free ((void*) byteArrVal);
                break;
            case GS_TYPE_SHORT_ARRAY:
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                size = (int) arr->Length();
                shortArrVal = (int16_t *) malloc(size * sizeof(int16_t));
                if (shortArrVal == NULL) {
                    return false;
                }
                for (i = 0; i < size; i++) {
                    checkConvert = SWIG_AsVal_int(arr->Get(i), &tmpInt);
                    shortArrVal[i] = (int16_t)tmpInt;
                    if (vbool || !SWIG_IsOK(checkConvert) ||
                        tmpInt < std::numeric_limits<int16_t>::min() ||
                        tmpInt > std::numeric_limits<int16_t>::max() ||
                        (!arr->Get(i)->IsInt32())) {
                            free((void*)shortArrVal);
                            shortArrVal = NULL;
                        return false;
                    }
                }
                ret = gsSetRowFieldByShortArray(row, column, (const int16_t *)shortArrVal, size);
                free ((void*) shortArrVal);
                break;
            case GS_TYPE_LONG_ARRAY:
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                size = (int) arr->Length();
                longArrVal = (int64_t *) malloc(size * sizeof(int64_t));
                if (longArrVal == NULL) {
                    return false;
                }
                for (i = 0; i < size; i++) {
                    checkConvert = SWIG_AsVal_long(arr->Get(i), &longArrVal[i]);
                    if (!SWIG_IsOK(checkConvert)){
                        free((void*)longArrVal);
                        longArrVal = NULL;
                        return false;
                    }
                }
                ret = gsSetRowFieldByLongArray(row, column, (const int64_t *)longArrVal, size);
                free ((void*) longArrVal);
                break;
            case GS_TYPE_FLOAT_ARRAY:
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                size = (int) arr->Length();
                floatArrVal = (float *) malloc(size * sizeof(float));
                if (floatArrVal == NULL) {
                    return false;
                }
                for (i = 0; i < size; i++) {
                    vbool = convertObjectToFloat(arr->Get(i), &floatArrVal[i]);
                    if (!vbool) {
                        free((void*)floatArrVal);
                        floatArrVal = NULL;
                        return false;
                    }
                }
                ret = gsSetRowFieldByFloatArray(row, column, (const float *) floatArrVal, size);
                free ((void*) floatArrVal);
                break;
            case GS_TYPE_DOUBLE_ARRAY:
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                size = (int) arr->Length();
                doubleArrVal = (double *) malloc(size * sizeof(double));
                if (doubleArrVal == NULL) {
                    return false;
                }
                for (i = 0; i < size; i++) {
                    vbool = convertObjectToDouble(arr->Get(i), &tmpDouble);
                    doubleArrVal[i] = tmpDouble;
                    if (!vbool){
                        free((void*)doubleArrVal);
                        doubleArrVal = NULL;
                        return false;
                    }
                }
                ret = gsSetRowFieldByDoubleArray(row, column, (const double *)doubleArrVal, size);
                free ((void*) doubleArrVal);
                break;
            case GS_TYPE_TIMESTAMP_ARRAY:
                if(!value->IsArray()) {
                    return false;
                }
                arr = v8::Local<v8::Array>::Cast(value);
                size = (int) arr->Length();
                timestampArrVal = (GSTimestamp *) malloc(size * sizeof(GSTimestamp));
                if (timestampArrVal == NULL) {
                    return false;
                }
                bool checkRet;
                for (i = 0; i < size; i++) {
                    checkRet = convertObjectToGSTimestamp(arr->Get(i), (timestampArrVal + i));
                    if (!checkRet) {
                        free((void*)timestampArrVal);
                        timestampArrVal = NULL;
                        return false;
                    }
                }
                ret = gsSetRowFieldByTimestampArray(row, column, (const GSTimestamp *)timestampArrVal, size);
                free ((void*) timestampArrVal);
                break;
            default:
                //Not support for now
                return false;
                break;
        }
        return (ret == GS_RESULT_OK);
    }
}

/**
* Typemaps for put_container() function
*/
%typemap(in, fragment = "SWIG_AsCharPtrAndSize") (const GSColumnInfo* props, int propsCount)
(v8::Local<v8::Array> arr, v8::Local<v8::Array> colInfo, v8::Local<v8::Array> keys, size_t size = 0, int* alloc = 0, int res, char* v = 0) {
//Convert js arrays into GSColumnInfo properties
    if(!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }
    arr = v8::Local<v8::Array>::Cast($input);
    $2 = (int) arr->Length();
    $1 = NULL;
    if($2 > 0) {
        $1 = (GSColumnInfo *) malloc($2*sizeof(GSColumnInfo));
        alloc = (int*) malloc($2*sizeof(int));
        if($1 == NULL || alloc == NULL) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        memset($1, 0x0, $2*sizeof(GSColumnInfo));
        memset(alloc, 0x0, $2*sizeof(int));

        for(int i = 0; i < $2; i++) {
            if(!(arr->Get(i))->IsArray()) {
                SWIG_V8_Raise("Expected array property as ColumnInfo element");
                SWIG_fail;
            }

            colInfo = v8::Local<v8::Array>::Cast(arr->Get(i));
            if ((int)colInfo->Length() < 2 || (int)colInfo->Length() > 3) {
                SWIG_V8_Raise("Expected 2 or 3 elements for ColumnInfo property");
                SWIG_fail;
            }

            res = SWIG_AsCharPtrAndSize(colInfo->Get(0), &v, &size, &alloc[i]);
            if (!SWIG_IsOK(res)) {
                %variable_fail(res, "String", "Column name");
            }

            if(!colInfo->Get(1)->IsInt32()) {
                SWIG_V8_Raise("Expected Integer as type of Column type");
                SWIG_fail;
            }

            $1[i].name = v;
            $1[i].type = (int) colInfo->Get(1)->Uint32Value();
            
%#if GS_COMPATIBILITY_SUPPORT_3_5
            if ((int)colInfo->Length() == 3) {
                v8::Local<v8::Value> options = colInfo->Get(2);

                if(!options->IsInt32()) {
                    SWIG_V8_Raise("Expected Integer as type of Column options");
                    SWIG_fail;
                }

                $1[i].options = (int) options->Uint32Value();
            }
%#endif
        }
    }
}

%typemap(typecheck) (const GSColumnInfo* props, int propsCount) {
    $1 = (!$input->IsArray()) ? 1 : 0;
}

%typemap(freearg) (const GSColumnInfo* props, int propsCount) (int i) {
    if ($1) {
        for (i = 0; i < $2; i++) {
            if (alloc$argnum[i] == SWIG_NEWOBJ) {
                %delete_array($1[i].name);
            }
        }
        free((void *) $1);
    }

    if (alloc$argnum) {
        free(alloc$argnum);
    }
}

/**
* Typemaps for set_properties() function
*/
%typemap(in, fragment = "SWIG_AsCharPtrAndSize") (const GSPropertyEntry* props, int propsCount)
(v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, int i, int j, size_t size = 0, int* alloc = 0, int res, char* v = 0) {
    if(!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    $2 = (int) keys->Length();
    $1 = NULL;
    if($2 > 0) {
        $1 = (GSPropertyEntry *) malloc($2*sizeof(GSPropertyEntry));
        alloc = (int*) malloc($2 * 2 * sizeof(int));
        if($1 == NULL || alloc == NULL) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        memset(alloc, 0, $2 * 2 * sizeof(int));

        j = 0;
        for(int i = 0; i < $2; i++) {
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &v, &size, &alloc[j]);
            if (!SWIG_IsOK(res)) {
                %variable_fail(res, "String", "name");
            }

            $1[i].name = v;
            res = SWIG_AsCharPtrAndSize(obj->Get(keys->Get(i)), &v, &size, &alloc[j + 1]);
            if (!SWIG_IsOK(res)) {
                %variable_fail(res, "String", "value");
            }
            $1[i].value = v;
            j+=2;
        }
    }
}

%typemap(freearg) (const GSPropertyEntry* props, int propsCount) (int i = 0, int j = 0) {
    if ($1) {
        for (i = 0; i < $2; i++) {
            if (alloc$argnum[j] == SWIG_NEWOBJ) {
                %delete_array($1[i].name);
            }
            if (alloc$argnum[j + 1] == SWIG_NEWOBJ) {
                %delete_array($1[i].value);
            }
            j += 2;
        }
        free((void *) $1);
    }

    if (alloc$argnum) {
        free(alloc$argnum);
    }
}

/**
* Typemaps for get_store() function
*/
%typemap(in, fragment = "SWIG_AsCharPtrAndSize") (const char* host=NULL, int32_t port=NULL, const char* cluster_name=NULL,
        const char* database=NULL, const char* username=NULL, const char* password=NULL,
        const char* notification_member=NULL, const char* notification_provider=NULL) 
        (v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, int i, int j, size_t size = 0, int* alloc = 0, int res, char* name = 0, char* v = 0){
    if(!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    int len = (int) keys->Length();
    if(len > 0) {
        alloc = (int*) malloc(len * 2 * sizeof(int));
        memset(alloc, 0, len * 2 * sizeof(int));

        j = 0;
        for(int i = 0; i < len; i++) {
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &name, &size, &alloc[j]);
            if (!SWIG_IsOK(res)) {
                %variable_fail(res, "String", "name");
            }
            res = SWIG_AsCharPtrAndSize(obj->Get(keys->Get(i)), &v, &size, &alloc[j + 1]);
            if (!SWIG_IsOK(res)) {
                %variable_fail(res, "String", "value");
            }
            if (strcmp(name, "host") == 0){ 
                $1 = v;
            } else if (strcmp(name, "port") == 0){
                $2 = atoi(v);
            } else if (strcmp(name, "cluster_name") == 0) {
                $3 = v;
            } else if (strcmp(name, "database") == 0){
                $4 = v;
            } else if (strcmp(name, "username") == 0){
                $5 = v;
            } else if (strcmp(name, "password") == 0){
                $6 = v;
            } else if (strcmp(name, "notification_member") == 0){
                $7 = v;
            } else if(strcmp(name, "notification_provider") == 0){
                $8 = v;
            } else {
                SWIG_V8_Raise("Invalid Property");
                SWIG_fail;
            }

            j += 2;
        }
    }
}

%typemap(freearg) (const char* host=NULL, int32_t port=NULL, const char* cluster_name=NULL,
        const char* database=NULL, const char* username=NULL, const char* password=NULL,
        const char* notification_member=NULL, const char* notification_provider=NULL) {
    if (alloc$argnum) {
        free(alloc$argnum);
    }
}

/**
* Typemaps for fetch_all() function
*/
%typemap(in) (GSQuery* const* queryList, size_t queryCount)
(v8::Local<v8::Array> arr, v8::Local<v8::Value> query, griddb::Query *vquery, int res = 0) {
    if(!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }
    arr = v8::Local<v8::Array>::Cast($input);
    $2 = (int) arr->Length();
    $1 = NULL;
    if($2 > 0) {
        $1 = (GSQuery**) malloc($2*sizeof(GSQuery*));
        if($1 == NULL) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        for(int i = 0; i < $2; i++) {
            query = arr->Get(i);

            res = SWIG_ConvertPtr(query, (void**)&vquery, $descriptor(griddb::Query*), 0);
            if (!SWIG_IsOK(res)) {
                SWIG_V8_Raise("Convert pointer failed");
                SWIG_fail;
            }
            $1[i] = vquery->gs_ptr();
        }
    }
}

%typemap(freearg) (GSQuery* const* queryList, size_t queryCount) {
    if ($1) {
        free((void *) $1);
    }
}

/**
* Typemaps output for partition controller function
*/
%typemap(in, numinputs=0) (const GSChar *const ** stringList, size_t *size) (GSChar **nameList1, size_t size1) {
    $1 = &nameList1;
    $2 = &size1;
}

%typemap(argout,numinputs=0) (const GSChar *const ** stringList, size_t *size)
(v8::Local<v8::Array> arr, v8::Handle<v8::String> val) {
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
    arr = v8::Array::New(size1$argnum);
%#else
    arr = v8::Array::New(v8::Isolate::GetCurrent(), size1$argnum);
%#endif
    for(int i = 0; i < size1$argnum; i++) {
        val = SWIGV8_STRING_NEW2(nameList1$argnum[i], strlen(nameList1$argnum[i]));
        arr->Set(i, val);
    }

    $result = arr;
}

%typemap(in, numinputs=0) (const int **intList, size_t *size) (int *intList1, size_t size1) {
    $1 = &intList1;
    $2 = &size1;
}

%typemap(argout,numinputs=0) (const int **intList, size_t *size)
(v8::Local<v8::Array> arr, v8::Handle<v8::Integer> val) {
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
    arr = v8::Array::New(size1$argnum);
%#else
    arr = v8::Array::New(v8::Isolate::GetCurrent(), size1$argnum);
%#endif
    for(int i = 0; i < size1$argnum; i++) {
        val = SWIGV8_INTEGER_NEW(intList1$argnum[i]);
        arr->Set(i, val);
    }

    $result = arr;
}

%typemap(in, numinputs=0) (const long **longList, size_t *size) (long *longList1, size_t size1) {
    $1 = &longList1;
    $2 = &size1;
}

%typemap(argout,numinputs=0) (const long **longList, size_t *size)
(v8::Local<v8::Array> arr, v8::Handle<v8::Number> val) {
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
    arr = v8::Array::New(size1$argnum);
%#else
    arr = v8::Array::New(v8::Isolate::GetCurrent(), size1$argnum);
%#endif
    for(int i = 0; i < size1$argnum; i++) {
        val = SWIGV8_NUMBER_NEW(longList1$argnum[i]);
        arr->Set(i, val);
    }

    $result = arr;
}

// set_field_as_blob
%typemap(in) (const GSBlob *fieldValue) (size_t size1 = 0, int* alloc = 0, int res, char* v = 0) {
    if(!$input->IsString()){
        SWIG_V8_Raise("Expected string as input");
        SWIG_fail;
    }
    $1 = (GSBlob*) malloc(sizeof(GSBlob));

    alloc = (int*) malloc(sizeof(int));
    memset(alloc, 0x0, sizeof(int));
    res = SWIG_AsCharPtrAndSize($input, &v, &size1, alloc);
    if (!SWIG_IsOK(res)) {
        %variable_fail(res, "String", "GSBlob");
    }

    $1->size = ($input->ToString())->Length();
    $1->data = v;
}

%typemap(freearg) (const GSBlob *fieldValue) {
    if ($1) {
        free((void *) $1);
    }
}

%typemap(in, numinputs = 0) (GSBlob *value) (GSBlob pValue) {
    $1 = &pValue;
}

// Get_field_as_blob
%typemap(argout) (GSBlob *value) {
    $result = SWIGV8_STRING_NEW2((const char*)pValue$argnum.data, pValue$argnum.size);
}

/*
* typemap for get function in AggregationResult class
*/
%typemap(in, numinputs = 0) (griddb::Field *agValue) (griddb::Field tmpAgValue){
    $1 = &tmpAgValue;
}
%typemap(argout, fragment = "convertFieldToObject") (griddb::Field *agValue) {
    $result = convertFieldToObject(tmpAgValue$argnum);
}

/**
* Typemaps for put_row() function
*/
%typemap(in, fragment= "convertObjectToGSRowField") (griddb::Row* row) {
    if(!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }
    v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast($input);
    int leng = (int)arr->Length();
    GSRow *tmpRow = arg1->getGSRowPtr();
    int colNum = arg1->getColumnCount();
    GSType* typeList = arg1->getGSTypeList();
    for(int i = 0; i < leng; i++) {
        GSType type = typeList[i];
        if(!(convertObjectToGSRowField(tmpRow, i, arr->Get(i), type))) {
            %variable_fail(1, "String", "can not create row based on input");
        }
    }
}
%typemap(freearg) (griddb::Row *row) {
}

/**
* Typemaps for put_row() function
*/
%typemap(in, fragment="convertObjectToGSRowField") (griddb::Row *rowContainer) {
    if(!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }
    v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast($input);
    int leng = (int)arr->Length();

    if (leng != arg1->getColumnCount()) {
        SWIG_V8_Raise("Num row is different with container info");
        SWIG_fail;
    }
    GSType* typeList = arg1->getGSTypeList();
    GSType type;
    GSRow* row;
    row = arg1->getGSRowPtr();
    for(int i = 0; i < leng; i++) {
        type = typeList[i];
        if(!(convertObjectToGSRowField(row, i, arr->Get(i), type))) {
            char errorMsg[60];
            sprintf(errorMsg, "Invalid value for column %d, type should be : %d", i, type);
            SWIG_V8_Raise(errorMsg);
            SWIG_fail;
        }
    }
}
%typemap(freearg) (griddb::Row *row) {
}

/*
* typemap for get_row
*/
%typemap(in, fragment = "convertObjectToFieldWithType") (griddb::Field* keyFields) {
    if ($input->IsNull() || $input->IsUndefined()) {
        $1 = NULL;
    } else {
        GSType* typeList = arg1->getGSTypeList();
        GSType type = typeList[0];
        $1 = (griddb::Field *)malloc(sizeof(griddb::Field));
        if(!convertObjectToFieldWithType(*$1, $input, type)) {
            SWIG_V8_Raise("can not convert to row filed");
            SWIG_fail;
        }
    }
}

%typemap(freearg) (griddb::Field* keyFields) {
    if($1) {
        free((void*)$1);
    }
}

%typemap(in, numinputs = 0) (griddb::Row *rowdata) {
    $1 = NULL;
}

%typemap(freearg) (griddb::Row *rowdata) {
}

%typemap(argout, fragment = "convertGSRowFieldToObject") (griddb::Row *rowdata) (v8::Local<v8::Array> obj, v8::Handle<v8::Value> val)%{
    GSRow* row;
    row = arg1->getGSRowPtr();
#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
    obj = v8::Array::New(arg1->getColumnCount());
#else
    obj = v8::Array::New(v8::Isolate::GetCurrent(), arg1->getColumnCount());
#endif
    for(int i = 0; i < arg1->getColumnCount(); i++) {
        obj->Set(i, convertGSRowFieldToObject(row, i, arg1->timestamp_output_with_float));
    }
    $result = obj;
%}


/**
 * Typemaps for Store.multi_put
 */
%typemap(in, fragment="convertObjectToFieldWithType", fragment = "SWIG_AsCharPtrAndSize") (GSRow*** listRow, const int *listRowContainerCount, const char ** listContainerName, size_t containerCount)
(v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, v8::Local<v8::Array> arr, int res = 0, v8::Local<v8::Array> rowArr,
size_t sizeTmp = 0, int* alloc = 0, char* v = 0){
    if(!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    $1 = NULL;
    $2 = NULL;
    $3 = NULL;
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    $4 = (size_t) keys->Length();
    griddb::Container* tmpContainer;

    if($4 > 0) {
        $1 = new GSRow**[$4];
        $2 = (int*)malloc($4 * sizeof(int));
        $3 = (char **)malloc($4 * sizeof(char*));
        int i = 0;
        int j = 0;
        
        alloc = (int*) malloc($4*sizeof(int));
        if($1 == NULL || alloc == NULL) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        memset(alloc, 0x0, $4*sizeof(int));

        for(int i = 0; i < $4; i++) {
            // Get container name
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &v, &sizeTmp, &alloc[i]);
            if(!SWIG_IsOK(res)) {
                %variable_fail(res, "String", "containerName");
            }
            $3[i] = v;

            // Get row
            if(!(obj->Get(keys->Get(i)))->IsArray()) {
                SWIG_V8_Raise("Expected an array as rowList");
                SWIG_fail;
            }

            arr = v8::Local<v8::Array>::Cast(obj->Get(keys->Get(i)));
            $2[i] = (int) arr->Length();
            $1[i] = new GSRow* [$2[i]];

            //Get container info
            griddb::ContainerInfo* containerInfoTmp = arg1->get_container_info($3[i]);
            ColumnInfoList infoListTmp = containerInfoTmp->get_column_info_list();
            int* typeArr = (int*) malloc(infoListTmp.size * sizeof(int));
            for (int m = 0; m < infoListTmp.size; m++) {
                typeArr[m] = infoListTmp.columnInfo[m].type;
            }
            tmpContainer = arg1->get_container($3[i]);
            GSResult ret;
            for(int j = 0; j < $2[i]; j++) {
                ret = gsCreateRowByContainer(tmpContainer->getGSContainerPtr(), &$1[i][j]);
                rowArr = v8::Local<v8::Array>::Cast(arr->Get(j));
                int rowLen = (int) rowArr->Length();
                int k;
                for(k = 0; k < rowLen; k++) {
                    if (!(convertObjectToGSRowField($1[i][j], k, rowArr->Get(k), typeArr[k]))) {
                        char errorMsg[60];
                        sprintf(errorMsg, "Invalid value for column %d, type should be : %d", k, typeArr[k]);
                        SWIG_V8_Raise(errorMsg);
                        SWIG_fail;
                        delete containerInfoTmp;
                        free((void *) typeArr);
                    }
                }
            }
        }
    }
}

%typemap(freearg) (GSRow*** listRow, const int *listRowContainerCount, const char ** listContainerName, size_t containerCount) {
    for(int i = 0; i < $4; i++) {
        if($1[i]) {
            for(int j = 0; j < $2[i]; j++) {
                gsCloseRow(&$1[i][j]);
            }
            delete $1[i];
        }
    }
    if($1) delete $1;
    if($2) delete $2;
    if($3) delete $3;
}

/**
* Typemaps input for Store.multi_get() function
*/
%typemap(in) (const GSRowKeyPredicateEntry *const * predicateList, size_t predicateCount)
(v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, GSRowKeyPredicateEntry* pList,
griddb::RowKeyPredicate *vpredicate, int res = 0, size_t size = 0, int* alloc = 0, char* v = 0) {
    if(!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    $2 = (int) keys->Length();
    $1 = NULL;
    if($2 > 0) {
        pList = (GSRowKeyPredicateEntry*) malloc($2*sizeof(GSRowKeyPredicateEntry));
        if(pList == NULL) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        $1 = &pList;
        alloc = (int*) malloc($2 * 2 * sizeof(int));
        if($1 == NULL || alloc == NULL) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        memset(alloc, 0, $2 * 2 * sizeof(int));
        for(int i = 0; i < $2; i++) {
            GSRowKeyPredicateEntry *predicateEntry = &pList[i];
            // Get container name
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &v, &size, &alloc[i]);
            if(!SWIG_IsOK(res)) {
                %variable_fail(res, "String", "containerName");
            }
            predicateEntry->containerName = v;

            // Get predicate
            res = SWIG_ConvertPtr((obj->Get(keys->Get(i))), (void**)&vpredicate, $descriptor(griddb::RowKeyPredicate*), 0);
            if (!SWIG_IsOK(res)) {
                SWIG_V8_Raise("Convert RowKeyPredicate pointer failed");
                SWIG_fail;
            }
            predicateEntry->predicate = vpredicate->gs_ptr();
        }
    }
}

%typemap(freearg) (const GSRowKeyPredicateEntry *const * predicateList, size_t predicateCount) (int i, GSRowKeyPredicateEntry* pList) {
    if ($1 && *$1) {
        pList = *$1;
        for(i = 0; i < $2; i++) {
            if(pList[i].containerName){
                if (alloc$argnum[i] == SWIG_NEWOBJ) {
                    %delete_array(pList[i].containerName);
                }
            }
        }
        free((void *) pList);
    }
}

/**
 * Typemaps output for Store.multi_get() function
 */
%typemap(in, numinputs = 0) (GSContainerRowEntry **entryList, size_t* containerCount, int **colNumList) 
        (GSContainerRowEntry *tmpEntryList, size_t tmpContainerCount, int *tmpcolNumList) {
    $1 = &tmpEntryList;
    $2 = &tmpContainerCount;
    $3 = &tmpcolNumList;
}

%typemap(argout) (GSContainerRowEntry **entryList, size_t* containerCount, int **colNumList) 
(v8::Local<v8::Object> obj, v8::Local<v8::Array> arr, v8::Local<v8::Array> rowArr,
v8::Handle<v8::String> key, v8::Handle<v8::Value> value, GSRow* row) {
    obj = SWIGV8_OBJECT_NEW();
    int numContainer = (int) *$2;
    for(int i = 0; i < numContainer; i++) {
        key = SWIGV8_STRING_NEW2((*$1)[i].containerName, strlen((char*)(*$1)[i].containerName));

%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
        arr = v8::Array::New((int)(*$1)[i].rowCount);
%#else
        arr = v8::Array::New(v8::Isolate::GetCurrent(), (int)(*$1)[i].rowCount);
%#endif
    
        for(int j = 0; j < (*$1)[i].rowCount; j++) {
            row = (GSRow*)(*$1)[i].rowList[j];
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
            rowArr = v8::Array::New((int)(*$3)[i]);
%#else
            rowArr = v8::Array::New(v8::Isolate::GetCurrent(), (int)(*$3)[i]);
%#endif
            for(int k = 0; k < (*$3)[i]; k++) {
                rowArr->Set(k, convertGSRowFieldToObject(row, k, arg1->timestamp_output_with_float));
            }
            arr->Set(j, rowArr);
        }
        obj->Set(key, arr);
    }
    $result = obj;
}

%typemap(freearg) (GSContainerRowEntry **entryList, size_t* containerCount, int **colNumList) {
}

/**
 * Create typemap for RowKeyPredicate.set_range
 */
%typemap(in, fragment= "convertObjectToFieldWithType") (griddb::Field* startKey) {
    griddb::Field* startKey1 = (griddb::Field*) malloc(sizeof(griddb::Field));
    GSType type = arg1->get_key_type();
    if(!(convertObjectToFieldWithType(*startKey1, $input, type))) {
        SWIG_V8_Raise("Can not create row based on input");
        SWIG_fail;
    }
    $1 = startKey1;
}

%typemap(freearg) (griddb::Field* startKey) {
    if($1) {
        free((void*)$1);
    }
}

%typemap(in, fragment= "convertObjectToFieldWithType") (griddb::Field* finishKey ) {
    griddb::Field* finishKey1 = (griddb::Field *) malloc(sizeof(griddb::Field));
    GSType type = arg1->get_key_type();

    if(!(convertObjectToFieldWithType(*finishKey1, $input, type))) {
        SWIG_V8_Raise("Can not create row based on input");
        SWIG_fail;
    }
    $1 = finishKey1;
}

%typemap(freearg) (griddb::Field* finishKey) {
    if($1) {
        free((void*)$1);
    }
}

/**
 * Typemap for RowKeyPredicate.get_range
 */
%typemap(in, numinputs = 0) (griddb::Field* startField, griddb::Field* finishField) (griddb::Field startKeyTmp, griddb::Field finishKeyTmp) {
    $1 = &startKeyTmp;
    $2 = &finishKeyTmp;
}

%typemap(argout, fragment="convertFieldToObject") (griddb::Field* startField, griddb::Field* finishField) {
    int length = 2;
    v8::Local<v8::Array> arr;// = v8::Array::New(length);
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
    arr = v8::Array::New(length);
%#else
    arr = v8::Array::New(v8::Isolate::GetCurrent(), length);
%#endif
    arr->Set(0,convertFieldToObject(startKeyTmp$argnum));
    arr->Set(1,convertFieldToObject(finishKeyTmp$argnum));
    $result = arr;
}

/**
 * Typemap for RowKeyPredicate.set_distinct_keys
 */
%typemap(in, fragment="convertObjectToFieldWithType") (const griddb::Field *keys, size_t keyCount) {
    if(!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }
    v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast($input);
    $2 = (int)arr->Length();
    $1 = NULL;
    if ($2 > 0) {
        $1 = (griddb::Field *) malloc($2 * sizeof(griddb::Field));
        if($1 == NULL) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        GSType type = arg1->get_key_type();
        for (int i = 0; i < $2; i++) {
            if (!(convertObjectToFieldWithType($1[i], arr->Get(i), type))) {
                SWIG_V8_Raise("Can not create row based on input");
                SWIG_fail;
            }
        }
    }
}

%typemap(freearg) (const griddb::Field *keys, size_t keyCount) {
    if($1) {
        free((void*)$1);
    }
}


/**
* Typemaps output for RowKeyPredicate.get_distinct_keys
*/
%typemap(in, numinputs=0) (griddb::Field **keys, size_t* keyCount) (griddb::Field *keys1, size_t keyCount1) {
  $1 = &keys1;
  $2 = &keyCount1;
}

%typemap(argout,numinputs=0, fragment="convertFieldToObject") (griddb::Field **keys, size_t* keyCount) {
    v8::Local<v8::Array> obj;
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
    obj = v8::Array::New(keyCount1$argnum);
%#else
    obj = v8::Array::New(v8::Isolate::GetCurrent(), keyCount1$argnum);
%#endif
    for (int i = 0; i < keyCount1$argnum; i++) {
        v8::Handle<v8::Value> value = convertFieldToObject(keys1$argnum[i]);
        obj->Set(i, value);
    }
    $result = obj;
}

%typemap(freearg) (griddb::Field **keys, size_t* keyCount) {
    if($1) {
        free((void*)* $1);
    }
}

/**
 * Typemap for Container::multi_put
 */
%typemap(in, fragment="convertObjectToGSRowField") (GSRow** listRowdata, int rowCount){
    if(!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }

    v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast($input);
    $2 = (size_t)arr->Length();

    if($2 > 0) {
        GSContainer *mContainer = arg1->getGSContainerPtr();
        GSType* typeList = arg1->getGSTypeList();
        $1 = new GSRow*[$2];
        int length;
        for (int i = 0; i < $2; i++) {
            v8::Local<v8::Array> fieldArr = v8::Local<v8::Array>::Cast(arr->Get(i));
            length = (int)fieldArr->Length();
            if (length != arg1->getColumnCount()) {
                SWIG_V8_Raise("Num row is different with container info");
                SWIG_fail;
            }
            GSResult ret = gsCreateRowByContainer(mContainer, &$1[i]);
            if (ret != GS_RESULT_OK) {
                SWIG_V8_Raise("Can't create GSRow");
                SWIG_fail;
            }
            for(int k = 0; k < length; k++) {
                GSType type = typeList[k];
                if (!(convertObjectToGSRowField($1[i], k, fieldArr->Get(k), type))) {
                    $2 = i+1;
                    char errorMsg[200];
                    sprintf(errorMsg, "Invalid value for row %d, column %d, type should be : %d", i, k, type);
                    SWIG_V8_Raise(errorMsg);
                    SWIG_fail;
                }
            }
        }
    }
}

%typemap(freearg) (griddb::Row** listRowdata, int rowCount) {
    if($1) {
        for (int rowNum = 0; rowNum < $2; rowNum++) {
            gsCloseRow(&$1[rowNum]);
        }
        delete $1;
    }
}

/**
 * Typemap for QueryAnalysisEntry.get()
 */
%typemap(in, numinputs = 0) (GSQueryAnalysisEntry* queryAnalysis) (GSQueryAnalysisEntry queryAnalysis1) {
    $1 = &queryAnalysis1;
}

%typemap(argout) (GSQueryAnalysisEntry* queryAnalysis){
    const int size = 6;
    v8::Local<v8::Array> obj;
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
    obj = v8::Array::New(size);
%#else
    obj = v8::Array::New(v8::Isolate::GetCurrent(), size);
%#endif
    obj->Set(0, SWIGV8_INTEGER_NEW($1->id));
    obj->Set(1, SWIGV8_INTEGER_NEW($1->depth));
    v8::Handle<v8::String> str = SWIGV8_STRING_NEW2($1->type, strlen((char*)$1->type));
    obj->Set(2, str);
    str = SWIGV8_STRING_NEW2($1->valueType, strlen((char*)$1->valueType));
    obj->Set(3, str);
    str = SWIGV8_STRING_NEW2($1->value, strlen((char*)$1->value));
    obj->Set(4, str);
    str = SWIGV8_STRING_NEW2($1->statement, strlen((char*)$1->statement));
    obj->Set(5, str);

    $result = obj;
}


/**
 * Typemap for Rowset::next()
 */
%typemap(in, numinputs = 0) (GSRowSetType* type, griddb::Row* row, bool* hasNextRow,
        griddb::QueryAnalysisEntry** queryAnalysis, griddb::AggregationResult** aggResult)
    (GSRowSetType typeTmp, griddb::Row rowTmp, bool hasNextRowTmp,
    griddb::QueryAnalysisEntry* queryAnalysisTmp, griddb::AggregationResult* aggResultTmp) {
    $1 = &typeTmp;
    $2 = &rowTmp;
    $3 = &hasNextRowTmp;
    queryAnalysisTmp = new griddb::QueryAnalysisEntry(NULL);
    $4 = &queryAnalysisTmp;
    aggResultTmp = new griddb::AggregationResult(NULL);
    $5 = &aggResultTmp;
}

%typemap(argout, fragment = "convertFieldToObject") (GSRowSetType* type, griddb::Row* row, bool* hasNextRow,
        griddb::QueryAnalysisEntry** queryAnalysis, griddb::AggregationResult** aggResult) 
    (v8::Local<v8::Array> obj, v8::Handle<v8::Value> value, GSRow* row){
    switch(typeTmp$argnum) {
        case (GS_ROW_SET_CONTAINER_ROWS):
            if (hasNextRowTmp$argnum == false) {
                SWIGV8_NULL();
//                return;
            } else {
                row = arg1->getGSRowPtr();
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
                obj = v8::Array::New(rowTmp$argnum.get_count());
%#else
                obj = v8::Array::New(v8::Isolate::GetCurrent(), rowTmp$argnum.get_count());
%#endif
                if(obj->IsNull()) {
                    SWIG_V8_Raise("Memory allocation error");
                    SWIG_fail;
                }
                for(int i = 0; i < arg1->getColumnCount(); i++) {
                    obj->Set(i, convertGSRowFieldToObject(row, i, arg1->timestamp_output_with_float));
                }
                $result = obj;
            }
            break;
        case (GS_ROW_SET_AGGREGATION_RESULT):
            if (hasNextRowTmp$argnum == true) {
                value = SWIG_V8_NewPointerObj((void *)aggResultTmp$argnum, $descriptor(griddb::AggregationResult *), 0);
                $result = value;
            }
            break;
        case (GS_ROW_SET_QUERY_ANALYSIS):
            if (hasNextRowTmp$argnum == true) {
                value = SWIG_V8_NewPointerObj((void *)queryAnalysisTmp$argnum, $descriptor(griddb::QueryAnalysisEntry *), 0);
                $result = value;
            }
            break;
        default:
            SWIG_fail;
            break;
    }
    //return $result;
}

//attribute ContainerInfo::column_info_list
%typemap(in) (ColumnInfoList*) 
        (v8::Local<v8::Array> arr, v8::Local<v8::Array> colInfo, v8::Local<v8::Array> keys, size_t sizeTmp = 0, int* alloc = 0, int res, char* v = 0) {

    if(!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }
    v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast($input);
    size_t len = (size_t)arr->Length();
    GSColumnInfo* containerInfo;
    $1 = (ColumnInfoList*) malloc(sizeof(ColumnInfoList));
    if(len) {
        containerInfo = (GSColumnInfo*) malloc(len * sizeof(GSColumnInfo));
        alloc = (int*) malloc(len*sizeof(int));
        if(containerInfo == NULL || alloc == NULL) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        memset(containerInfo, 0x0, len*sizeof(GSColumnInfo));
        memset(alloc, 0x0, len*sizeof(int));

        for(int i = 0; i < len; i++) {
            if(!(arr->Get(i))->IsArray()) {
                SWIG_V8_Raise("Expected array property as ColumnInfo element");
                SWIG_fail;
            }

            colInfo = v8::Local<v8::Array>::Cast(arr->Get(i));
            if (colInfo->Length() < 2) {
                SWIG_V8_Raise("Expected at least two elements for ColumnInfo property");
                SWIG_fail;
            }
            v8::Local<v8::Value> key = colInfo->Get(0);
            v8::Local<v8::Value> value = colInfo->Get(1);

            res = SWIG_AsCharPtrAndSize(key, &v, &sizeTmp, &alloc[i]);
            if (!SWIG_IsOK(res)) {
                %variable_fail(res, "String", "Column name");
            }

            if(!value->IsNumber()) {
                SWIG_V8_Raise("Expected Integer as type of Column type");
                SWIG_fail;
            }

            containerInfo[i].name = v;
            containerInfo[i].type = value->Uint32Value();
            
            if (colInfo->Length() == 3) {
%#if GS_COMPATIBILITY_SUPPORT_3_5
                v8::Local<v8::Value> options = colInfo->Get(2);

                if(!options->IsNumber()) {
                    SWIG_V8_Raise("Expected Integer as type of Column options");
                    SWIG_fail;
                }

                containerInfo[i].options = options->Uint32Value();
%#else
                SWIG_V8_Raise("Expected two elements for ColumnInfo property");
                SWIG_fail;
%#endif
            }
        }
        $1->columnInfo = containerInfo;
        $1->size = len;
    }
}

%typemap(freearg) (ColumnInfoList*) {
    size_t len = $1->size;
    if (alloc$argnum) {
        for (int i =0; i < len; i++) {
            if (alloc$argnum[i]) {
                %delete_array($1->columnInfo[i].name);
            }
        }
        free(alloc$argnum);
    }
    if ($1->columnInfo) {
        free ((void *)$1->columnInfo);
    }
}

%typemap(out) (ColumnInfoList*) {
    v8::Local<v8::Array> obj;
    size_t len = $1->size;
    if (len > 0) {
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
        obj = v8::Array::New(len);
%#else
        obj = v8::Array::New(v8::Isolate::GetCurrent(), len);
%#endif
        if(obj->IsNull()) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        for (int i = 0; i < len; i++) {
            v8::Local<v8::Array> prop;
%#if GS_COMPATIBILITY_SUPPORT_3_5
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
            prop = v8::Array::New(3);
%#else
            prop = v8::Array::New(v8::Isolate::GetCurrent(), 3);
%#endif
            prop->Set(2, SWIGV8_NUMBER_NEW($1->columnInfo[i].options));
%#else
%#if (V8_MAJOR_VERSION-0) < 4 && (SWIG_V8_VERSION < 0x032318)
            prop = v8::Array::New(2);
%#else
            prop = v8::Array::New(v8::Isolate::GetCurrent(), 2);
%#endif
%#endif
            v8::Handle<v8::String> str = SWIGV8_STRING_NEW2($1->columnInfo[i].name, strlen((char*)$1->columnInfo[i].name));
            prop->Set(0, str);
            prop->Set(1, SWIGV8_NUMBER_NEW($1->columnInfo[i].type));
            obj->Set(i, prop);
        }
    }
    $result = obj;
}
