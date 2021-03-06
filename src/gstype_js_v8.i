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

#define UTC_TIMESTAMP_MAX 253402300799.999 // Max timestamp in seconds
%{
#include <ctime>
#include <limits>
#include <node_buffer.h>
#include <nan.h>
%}

// rename all method to camel cases
%rename("%(lowercamelcase)s", %$isfunction) "";
//Correct attribute name to camel case
%rename(timestampOutput) *::timestamp_output_with_float;
/*
 * ignore unnecessary functions
 */
%ignore griddb::Container::setOutputTimestamp;
%ignore griddb::RowSet::next_row;
%ignore griddb::RowSet::get_next_query_analysis;
%ignore griddb::RowSet::get_next_aggregation;
%ignore griddb::ContainerInfo::ContainerInfo(GSContainerInfo* containerInfo);
%ignore griddb::AggregationResult::setOutputTimestamp;
%ignore griddb::RowKeyPredicate::setOutputTimestamp;
%ignore griddb::RowSet::setOutputTimestamp;
%ignore griddb::Store::setOutputTimestamp;

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
//Read only attribute ContainerInfo::rowKey
%attribute(griddb::ContainerInfo, bool, rowKey, get_row_key_assigned, set_row_key_assigned);
//Read only attribute ContainerInfo::columnInfoList 
%attributeval(griddb::ContainerInfo, ColumnInfoList, columnInfoList, get_column_info_list, set_column_info_list);
//Read only attribute ContainerInfo::expiration 
%attribute(griddb::ContainerInfo, griddb::ExpirationInfo*, expiration, get_expiration_info, set_expiration_info);
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

%fragment("convertFieldToObject", "header", fragment = "convertTimestampToObject") {
static v8::Handle<v8::Value> convertFieldToObject(GSValue* value, GSType type, bool timestampToFloat = true) {

    size_t size;
    v8::Local<v8::Array> list;
    int i;
    switch (type) {
        case GS_TYPE_LONG:
            return SWIGV8_NUMBER_NEW(value->asLong);
        case GS_TYPE_STRING:
            return SWIGV8_STRING_NEW(value->asString);
%#if GS_COMPATIBILITY_SUPPORT_3_5
        case GS_TYPE_NULL:
            return SWIGV8_NULL();
%#endif
        case GS_TYPE_BLOB:
            return Nan::CopyBuffer((char *)value->asBlob.data, value->asBlob.size).ToLocalChecked();
        case GS_TYPE_BOOL:
            return SWIGV8_BOOLEAN_NEW((bool)value->asBool);
        case GS_TYPE_INTEGER:
            return SWIGV8_INT32_NEW(value->asInteger);
        case GS_TYPE_FLOAT:
            return SWIGV8_NUMBER_NEW(value->asFloat);
        case GS_TYPE_DOUBLE:
            return SWIGV8_NUMBER_NEW(value->asDouble);
        case GS_TYPE_TIMESTAMP:
            return convertTimestampToObject(&value->asTimestamp, timestampToFloat);
        case GS_TYPE_BYTE:
            return SWIGV8_INT32_NEW(value->asByte);
        case GS_TYPE_SHORT:
            return SWIGV8_INT32_NEW(value->asShort);
        case GS_TYPE_GEOMETRY:
            return SWIGV8_STRING_NEW(value->asGeometry);
        case GS_TYPE_INTEGER_ARRAY: {
            const int32_t *intArrVal;
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = value->asIntegerArray.size;
            intArrVal = value->asIntegerArray.elements;
%#else
            size = value->asArray.length;
            intArrVal = value->asArray.elements.asInteger;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIG_From_int(intArrVal[i]));
            }
            return list;
        }
        case GS_TYPE_STRING_ARRAY: {
            const GSChar *const *stringArrVal;
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = value->asStringArray.size;
            stringArrVal = value->asStringArray.elements;
%#else
            size = value->asArray.length;
            stringArrVal = value->asArray.elements.asString;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIGV8_STRING_NEW((GSChar *)stringArrVal[i]));
            }
            return list;
        }
        case GS_TYPE_BOOL_ARRAY: {
            const GSBool *boolArrVal;
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = value->asBoolArray.size;
            boolArrVal = field.value.asBoolArray.elements;
%#else
            size = value->asArray.length;
            boolArrVal = value->asArray.elements.asBool;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIG_From_bool(boolArrVal[i]));
            }
            return list;
        }
        case GS_TYPE_BYTE_ARRAY: {
            const int8_t *byteArrVal;
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = value->asByteArray.size;
            byteArrVal = value->asByteArray.elements;
%#else
            size = value->asArray.length;
            byteArrVal = value->asArray.elements.asByte;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIG_From_int(byteArrVal[i]));
            }
            return list;
        }
        case GS_TYPE_SHORT_ARRAY: {
            const int16_t *shortArrVal;
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = value->asShortArray.size;
            shortArrVal = value->asShortArray.elements;
%#else
            size = value->asArray.length;
            shortArrVal = value->asArray.elements.asShort;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIG_From_int(shortArrVal[i]));
            }
            return list;
        }
        case GS_TYPE_LONG_ARRAY: {
            const int64_t *longArrVal;
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = value->asLongArray.size;
            longArrVal = value->asLongArray.elements;
%#else
            size = value->asArray.length;
            longArrVal = value->asArray.elements.asLong;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIGV8_NUMBER_NEW(longArrVal[i]));
            }
            return list;
        }
        case GS_TYPE_FLOAT_ARRAY: {
            const float *floatArrVal;
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = value->asFloatArray.size;
            floatArrVal = value->asFloatArray.elements;
%#else
            size = value->asArray.length;
            floatArrVal = value->asArray.elements.asFloat;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIGV8_NUMBER_NEW(((float *)floatArrVal)[i]));
            }
            return list;
        }
        case GS_TYPE_DOUBLE_ARRAY: {
            const double *doubleArrVal;
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = value->asDoubleArray.size;
            doubleArrVal = value->asDoubleArray.elements;
%#else
            size = value->asArray.length;
            doubleArrVal = value->asArray.elements.asDouble;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, SWIGV8_NUMBER_NEW(((double *)doubleArrVal)[i]));
            }
            return list;
        }
        case GS_TYPE_TIMESTAMP_ARRAY: {
            const GSTimestamp *timestampArrVal;
%#if GS_COMPATIBILITY_VALUE_1_1_106
            size = value->asTimestampArray.size;
            timestampArrVal = value->asTimestampArray.elements;
%#else
            size = value->asArray.length;
            timestampArrVal = value->asArray.elements.asTimestamp;
%#endif
            list = SWIGV8_ARRAY_NEW();
            for (i = 0; i < size; i++) {
                list->Set(i, convertTimestampToObject((GSTimestamp*)&(timestampArrVal[i]), timestampToFloat));
            }
            return list;
        }
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
        fragment = "cleanStringArray", fragment = "cleanString") {
static GSChar** convertObjectToStringArray(v8::Local<v8::Value> value, int* size) {
    GSChar** arrString = NULL;
    size_t arraySize;
    int alloc = 0;
    char* v;
    v8::Local<v8::Array> arr;
    if (!value->IsArray()) {
        return NULL;
    }
    arr = v8::Local<v8::Array>::Cast(value);
    arraySize = (int) arr->Length();

    *size = (int)arraySize;
    arrString = (GSChar**) malloc(arraySize * sizeof(GSChar*));
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

        if (v) {
            arrString[i] = strdup(v);
            cleanString(v, alloc);
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
 * Support clean output of SWIG_AsCharPtrAndSize after used
 */
%fragment("cleanString", "header") {
static void cleanString(const GSChar* string, int alloc){
    if (!string) {
        return;
    }

    if (alloc == SWIG_NEWOBJ) {
        delete [] string;
    }
}
}

/**
 * Support check number is int64_t
 */
%fragment("isInt64", "header") {
static bool isInt64(double x) {
    return x == static_cast<double>(static_cast<int64_t>(x));
}
}
/**
 * Support convert type from object to long.
 */
%fragment("convertObjectToLong", "header", fragment = "isInt64") {
static bool convertObjectToLong(v8::Local<v8::Value> value, int64_t* longVal) {
    int checkConvert = 0;
    if (isInt64(value->NumberValue())) {
        //input can be integer
        checkConvert = SWIG_AsVal_long(value, longVal);
        if (!SWIG_IsOK(checkConvert)) {
            return false;
        }
        //When input value is integer, it should be between -9007199254740992(-2^53)/9007199254740992(2^53).
        return (-9007199254740992 <= *longVal && 9007199254740992 >= *longVal);
    } else {
        return false;
    }
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
%fragment("convertObjectToFloat", "header") {
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

        return (*floatValPtr <= std::numeric_limits<float>::max() &&
                *floatValPtr >= -1 *std::numeric_limits<float>::max());
    }
}
}
/**
 * Support convert type from object to GSTimestamp: input in target language can be :
 * datetime object, string or float
 */
%fragment("convertObjectToGSTimestamp", "header", fragment = "convertObjectToFloat", fragment = "cleanString") {
static bool convertObjectToGSTimestamp(v8::Local<v8::Value> value, GSTimestamp* timestamp) {
    int year, month, day, hour, minute, second, milliSecond, microSecond;
    size_t size = 0;
    int res;
    char* v = 0;
    int alloc;
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

        retConvertTimestamp = gsParseTime(v, timestamp);
        cleanString(v, alloc);
        return (retConvertTimestamp == GS_TRUE);
    } else if (value->IsNumber()) {
        *timestamp = value->NumberValue();
        if (*timestamp > (UTC_TIMESTAMP_MAX * 1000)) { //miliseconds
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
 * Support convert row key Field from NodeJS object to C Object with specific type
 */
%fragment("convertToRowKeyFieldWithType", "header", fragment = "SWIG_AsCharPtrAndSize"
        , fragment = "convertObjectToBool", fragment = "convertObjectToGSTimestamp"
        , fragment = "convertObjectToDouble", fragment = "convertObjectToLong"
        , fragment = "convertObjectToStringArray", fragment = "cleanString") {
static bool convertToRowKeyFieldWithType(griddb::Field &field, v8::Local<v8::Value> value, GSType type) {
    size_t size = 0;
    int res;
    char* v = 0;
    int alloc;
    int checkConvert = 0;

    field.type = type;

    if (value->IsNull() || value->IsUndefined()) {
        // Not support null
        return false;
    }

    switch (type) {
        case GS_TYPE_STRING:
            if (!value->IsString()) {
                return false;
            }
            res = SWIG_AsCharPtrAndSize(value, &v, &size, &alloc);
            if (!SWIG_IsOK(res)) {
               return false;
            }
            if (v) {
                field.value.asString = strdup(v);
                cleanString(v, alloc);
            } else {
                field.value.asString = NULL;
            }
            break;
        case GS_TYPE_INTEGER:
            if (!value->IsInt32()) {
                return false;
            }
            field.value.asInteger = value->IntegerValue();
            break;
        case GS_TYPE_LONG:
            return convertObjectToLong(value, &field.value.asLong);
            break;
        case GS_TYPE_TIMESTAMP:
            return convertObjectToGSTimestamp(value, &field.value.asTimestamp);
            break;
        default:
            //Not support for now
            return false;
            break;
    }
    return true;
}
}

%fragment("convertToFieldWithType", "header", fragment = "SWIG_AsCharPtrAndSize",
        fragment = "convertObjectToDouble", fragment = "convertObjectToGSTimestamp", 
        fragment = "convertObjectToBool", fragment = "convertObjectToFloat", 
        fragment = "convertObjectToStringArray", fragment = "cleanString",
        fragment = "convertObjectToLong") {
static bool convertToFieldWithType(GSRow *row, int column, v8::Local<v8::Value> value, GSType type) {
    int32_t intVal;
    size_t size;
    int tmpInt; //support convert to byte array, short array
    int res;
    bool vbool;
    int alloc;
    int i;
    GSResult ret;
    v8::Local<v8::Array> arr;

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
    switch (type) {
        case GS_TYPE_STRING: {
            GSChar* stringVal;
            if (!value->IsString()) {
                return false;
            }
            res = SWIG_AsCharPtrAndSize(value, &stringVal, &size, &alloc);
            if (!SWIG_IsOK(res)) {
                return false;
            }
            ret = gsSetRowFieldByString(row, column, stringVal);
            cleanString(stringVal, alloc);
            break;
        }
        case GS_TYPE_LONG: {
            int64_t longVal;
            vbool = convertObjectToLong(value, &longVal);
            if (!vbool) {
                return false;
            }
            ret = gsSetRowFieldByLong(row, column, longVal);
            break;
        }
        case GS_TYPE_BOOL: {
            GSBool boolVal;
            vbool = convertObjectToBool(value, (bool*)&boolVal);
            if (!vbool) {
                return false;
            }
            ret = gsSetRowFieldByBool(row, column, boolVal);
            break;
        }
        case GS_TYPE_BYTE: {
            if (!value->IsInt32()) {
                return false;
            }
            if (value->IntegerValue() < std::numeric_limits<int8_t>::min() || value->IntegerValue() > std::numeric_limits<int8_t>::max()) {
                return false;
            }
            ret = gsSetRowFieldByByte(row, column, value->IntegerValue());
            break;
        }
        case GS_TYPE_SHORT:
            if (!value->IsInt32()) {
                return false;
            }
            if (value->IntegerValue() < std::numeric_limits<int16_t>::min() || 
                    value->IntegerValue() > std::numeric_limits<int16_t>::max()) {
                return false;
            }
            ret = gsSetRowFieldByShort(row, column, value->IntegerValue());
            break;

        case GS_TYPE_INTEGER:
            if (!value->IsInt32()) {
                return false;
            }
            ret = gsSetRowFieldByInteger(row, column, value->IntegerValue());
            break;
        case GS_TYPE_FLOAT: {
            float floatVal;
            vbool = convertObjectToFloat(value, &floatVal);
            if (!vbool) {
                return false;
            }
            ret = gsSetRowFieldByFloat(row, column, floatVal);
            break;
        }
        case GS_TYPE_DOUBLE: {
            double doubleVal;
            vbool = convertObjectToDouble(value, &doubleVal);
            if (!vbool) {
                return false;
            }
            ret = gsSetRowFieldByDouble(row, column, doubleVal);
            break;
        }
        case GS_TYPE_TIMESTAMP: {
            GSTimestamp timestampVal;
            vbool = convertObjectToGSTimestamp(value, &timestampVal);
            if (!vbool) {
                return false;
            }
            ret = gsSetRowFieldByTimestamp(row, column, timestampVal);
            break;
        }
        case GS_TYPE_BLOB: {
            GSBlob blobVal;
            if (!node::Buffer::HasInstance(value)) {
                return false;
            }
            char* v = (char*) node::Buffer::Data(value);
            size = node::Buffer::Length (value);

            blobVal.data = v;
            blobVal.size = size;
            ret = gsSetRowFieldByBlob(row, column, (const GSBlob *)&blobVal);
            break;
        }
        case GS_TYPE_STRING_ARRAY: {
            const GSChar *const *stringArrVal;
            int length;
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
        }
        case GS_TYPE_GEOMETRY: {
            GSChar *geometryVal;
            if (!value->IsString()) {
                return false;
            }
            res = SWIG_AsCharPtrAndSize(value, &geometryVal, &size, &alloc);

            if (!SWIG_IsOK(res)) {
                return false;
            }
            ret = gsSetRowFieldByGeometry(row, column, geometryVal);
            cleanString(geometryVal, alloc);
            break;
        }
        case GS_TYPE_INTEGER_ARRAY: {
            int32_t *intArrVal;
            if (!value->IsArray()) {
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
        }
        case GS_TYPE_BOOL_ARRAY: {
            GSBool *boolArrVal;
            if (!value->IsArray()) {
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
        }
        case GS_TYPE_BYTE_ARRAY: {
            int8_t *byteArrVal;
            if (!value->IsArray()) {
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
        }
        case GS_TYPE_SHORT_ARRAY: {
            int16_t *shortArrVal;
            if (!value->IsArray()) {
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
                if (!SWIG_IsOK(checkConvert) ||
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
        }
        case GS_TYPE_LONG_ARRAY: {
            int64_t *longArrVal;
            if (!value->IsArray()) {
                return false;
            }
            arr = v8::Local<v8::Array>::Cast(value);
            size = (int) arr->Length();
            longArrVal = (int64_t *) malloc(size * sizeof(int64_t));
            if (longArrVal == NULL) {
                return false;
            }
            for (i = 0; i < size; i++) {
                vbool = convertObjectToLong(arr->Get(i), &longArrVal[i]);
                if (!vbool) {
                    free((void*)longArrVal);
                    longArrVal = NULL;
                    return false;
                }
            }
            ret = gsSetRowFieldByLongArray(row, column, (const int64_t *)longArrVal, size);
            free ((void*) longArrVal);
            break;
        }
        case GS_TYPE_FLOAT_ARRAY: {
            float *floatArrVal;
            if (!value->IsArray()) {
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
        }
        case GS_TYPE_DOUBLE_ARRAY: {
            double *doubleArrVal;
            double tmpDouble; //support convert to double array
            if (!value->IsArray()) {
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
                if (!vbool) {
                    free((void*)doubleArrVal);
                    doubleArrVal = NULL;
                    return false;
                }
            }
            ret = gsSetRowFieldByDoubleArray(row, column, (const double *)doubleArrVal, size);
            free ((void*) doubleArrVal);
            break;
        }
        case GS_TYPE_TIMESTAMP_ARRAY: {
            GSTimestamp *timestampArrVal;
            if (!value->IsArray()) {
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
        }
        default:
            //Not support for now
            return false;
            break;
    }
    return (ret == GS_RESULT_OK);
}
}

/**
* Typemaps for set_properties() function
*/
%typemap(in, fragment = "SWIG_AsCharPtrAndSize", fragment = "freeargSetProperties") (const GSPropertyEntry* props, int propsCount)
(v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, int j, size_t size = 0, int* alloc = 0, int res, char* v = 0) {
    if (!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    $2 = (int) keys->Length();
    $1 = NULL;
    if ($2 > 0) {
        $1 = (GSPropertyEntry *) malloc($2*sizeof(GSPropertyEntry));
        alloc = (int*) malloc($2 * 2 * sizeof(int));
        if ($1 == NULL || alloc == NULL) {
            freeargSetProperties($1, $2, alloc);
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        memset(alloc, 0, $2 * 2 * sizeof(int));

        j = 0;
        for (int i = 0; i < $2; i++) {
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &v, &size, &alloc[j]);
            if (!SWIG_IsOK(res)) {
                freeargSetProperties($1, $2, alloc);
                %variable_fail(res, "String", "name");
            }

            $1[i].name = v;
            res = SWIG_AsCharPtrAndSize(obj->Get(keys->Get(i)), &v, &size, &alloc[j + 1]);
            if (!SWIG_IsOK(res)) {
                freeargSetProperties($1, $2, alloc);
                %variable_fail(res, "String", "value");
            }
            $1[i].value = v;
            j+=2;
        }
    }
}

%typemap(freearg, fragment = "freeargSetProperties") (const GSPropertyEntry* props, int propsCount){
    freeargSetProperties($1, $2, alloc$argnum);
}

%fragment("freeargSetProperties", "header", fragment = "cleanString") {
    //SWIG does not include freearg in fail: label (not like Python, so we need this function)
static void freeargSetProperties(GSPropertyEntry* entry, int size, int* alloc) {
    int j = 0;
    if (entry) {
        for (int i = 0; i < size; i++) {
            cleanString(entry[i].name, alloc[j]);
            cleanString(entry[i].value, alloc[j + 1]);
            j += 2;
        }
        free((void *) entry);
        entry = NULL;
    }

    if (alloc) {
        free(alloc);
        alloc = NULL;
    }
}
}

/**
* Typemaps for get_store() function
*/
%typemap(in, numinputs = 1, fragment = "SWIG_AsCharPtrAndSize", fragment = "cleanString", fragment = "freeargGetStore") 
        (const char* host, int32_t port, const char* cluster_name, const char* database, const char* username, const char* password,
        const char* notification_member, const char* notification_provider) 
        (v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, int i, int j, size_t size = 0, int* alloc = 0, int res, char* v = 0) {
    if (!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    int len = (int) keys->Length();
    char* name = 0;
    $1 = NULL;
    $2 = 0;
    $3 = NULL;
    $4 = NULL;
    $5 = NULL;
    $6 = NULL;
    $7 = NULL;
    $8 = NULL;
    if (len > 0) {
        alloc = (int*) malloc(len * 2 * sizeof(int));
        memset(alloc, 0, len * 2 * sizeof(int));

        j = 0;
        for (int i = 0; i < len; i++) {
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &name, &size, &alloc[j]);
            if (!SWIG_IsOK(res)) {
                freeargGetStore($1, $3, $4, $5, $6, $7, $8, alloc);
                %variable_fail(res, "String", "name");
            }

            if (strcmp(name, "port") == 0) {
                //Input valid is number only
                if (obj->Get(keys->Get(i))->IsInt32()) {
                    $2 = obj->Get(keys->Get(i))->IntegerValue();
                } else {
                    freeargGetStore($1, $3, $4, $5, $6, $7, $8, alloc);
                    %variable_fail(res, "String", "value");
                }
            } else {
                res = SWIG_AsCharPtrAndSize(obj->Get(keys->Get(i)), &v, &size, &alloc[j + 1]);
                if (!SWIG_IsOK(res)) {
                    freeargGetStore($1, $3, $4, $5, $6, $7, $8, alloc);
                    %variable_fail(res, "String", "value");
                }
                if (strcmp(name, "host") == 0 && v) {
                    $1 = strdup(v);
                } else if (strcmp(name, "clusterName") == 0 && v) {
                    $3 = strdup(v);
                } else if (strcmp(name, "database") == 0 && v) {
                    $4 = strdup(v);
                } else if (strcmp(name, "username") == 0 && v) {
                    $5 = strdup(v);
                } else if (strcmp(name, "password") == 0 && v) {
                    $6 = strdup(v);
                } else if (strcmp(name, "notificationMember") == 0 && v) {
                    $7 = strdup(v);
                } else if (strcmp(name, "notificationProvider") == 0 && v) {
                    $8 = strdup(v);
                } else {
                    cleanString(name, alloc[j]);
                    freeargGetStore($1, $3, $4, $5, $6, $7, $8, alloc);
                    SWIG_V8_Raise("Invalid Property");
                    SWIG_fail;
                }
            }
            cleanString(name, alloc[j]);
            cleanString(v, alloc[j + 1]);

            j += 2;
        }
    }
}

%typemap(freearg, fragment = "freeargGetStore") (const char* host, int32_t port, const char* cluster_name,
        const char* database, const char* username, const char* password,
        const char* notification_member, const char* notification_provider) {
    freeargGetStore($1, $3, $4, $5, $6, $7, $8, alloc$argnum);
}

%fragment("freeargGetStore", "header") {
    //SWIG does not include freearg in fail: label (not like Python, so we need this function)
static void freeargGetStore(const char* host, const char* cluster_name,
        const char* database, const char* username, const char* password,
        const char* notification_member, const char* notification_provider, int* alloc) {
    if (host) {
        free((void*) host);
    }
    if (cluster_name) {
        free((void*) cluster_name);
    }
    if (database) {
        free((void*) database);
    }
    if (username) {
        free((void*) username);
    }
    if (password) {
        free((void*) password);
    }
    if (notification_member) {
        free((void*) notification_member);
    }
    if (notification_provider) {
        free((void*) notification_provider);
    }
    if (alloc) {
        free(alloc);
    }
}
}

/**
* Typemaps for fetch_all() function
*/
%typemap(in) (GSQuery* const* queryList, size_t queryCount)
(v8::Local<v8::Array> arr, v8::Local<v8::Value> query, griddb::Query *vquery, int res = 0) {
    if ($input->IsNull()) {
        $1 = NULL;
        $2 = 0;
    } else if (!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    } else {
        arr = v8::Local<v8::Array>::Cast($input);
        $2 = (int) arr->Length();
        $1 = NULL;
        if ($2 > 0) {
            $1 = (GSQuery**) malloc($2*sizeof(GSQuery*));
            if ($1 == NULL) {
                SWIG_V8_Raise("Memory allocation error");
                SWIG_fail;
            }
            for (int i = 0; i < $2; i++) {
                query = arr->Get(i);
                res = SWIG_ConvertPtr(query, (void**)&vquery, $descriptor(griddb::Query*), 0);
                if (!SWIG_IsOK(res)) {
                    if ($1) {
                        free((void *) $1);
                    }
                    SWIG_V8_Raise("Convert pointer failed");
                    SWIG_fail;
                }
                $1[i] = vquery->gs_ptr();
            }
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
%typemap(in, numinputs = 0) (const GSChar *const ** stringList, size_t *size) (GSChar **nameList1, size_t size1) {
    $1 = &nameList1;
    $2 = &size1;
}

%typemap(argout, numinputs = 0) (const GSChar *const ** stringList, size_t *size)
(v8::Local<v8::Array> arr, v8::Handle<v8::String> val) {
    arr = SWIGV8_ARRAY_NEW();
    for (int i = 0; i < size1$argnum; i++) {
        val = SWIGV8_STRING_NEW2(nameList1$argnum[i], strlen(nameList1$argnum[i]));
        arr->Set(i, val);
    }

    $result = arr;
}

%typemap(in, numinputs = 0) (const int **intList, size_t *size) (int *intList1, size_t size1) {
    $1 = &intList1;
    $2 = &size1;
}

%typemap(argout, numinputs = 0) (const int **intList, size_t *size)
(v8::Local<v8::Array> arr, v8::Handle<v8::Integer> val) {
    arr = SWIGV8_ARRAY_NEW();
    for (int i = 0; i < size1$argnum; i++) {
        val = SWIGV8_INTEGER_NEW(intList1$argnum[i]);
        arr->Set(i, val);
    }

    $result = arr;
}

%typemap(in, numinputs = 0) (const long **longList, size_t *size) (long *longList1, size_t size1) {
    $1 = &longList1;
    $2 = &size1;
}

%typemap(argout, numinputs = 0) (const long **longList, size_t *size)
(v8::Local<v8::Array> arr, v8::Handle<v8::Number> val) {
    arr = SWIGV8_ARRAY_NEW();
    for (int i = 0; i < size1$argnum; i++) {
        val = SWIGV8_NUMBER_NEW(longList1$argnum[i]);
        arr->Set(i, val);
    }

    $result = arr;
}

/*
* typemap for get function in AggregationResult class
*/
%typemap(in, numinputs = 0) (griddb::Field *agValue) (griddb::Field tmpAgValue) {
    $1 = &tmpAgValue;
}
%typemap(argout, fragment = "convertFieldToObject") (griddb::Field *agValue) {
    $result = convertFieldToObject(&($1->value), $1->type, arg1->timestamp_output_with_float);
}

/**
* Typemaps for put_row() function
*/
%typemap(in, fragment = "convertToFieldWithType") (GSRow* row) {
    if (!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }
    v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast($input);
    int leng = (int)arr->Length();
    GSRow *tmpRow = arg1->getGSRowPtr();
    int colNum = arg1->getColumnCount();
    GSType* typeList = arg1->getGSTypeList();
    for (int i = 0; i < leng; i++) {
        GSType type = typeList[i];
        if (!(convertToFieldWithType(tmpRow, i, arr->Get(i), type))) {
            %variable_fail(1, "String", "Can not create row based on input");
        }
    }
}

/**
* Typemaps for Container::put() function
*/
%typemap(in, fragment = "convertToFieldWithType") (GSRow *rowContainer) {
    if (!$input->IsArray()) {
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
    for (int i = 0; i < leng; i++) {
        type = typeList[i];
        if (!(convertToFieldWithType(row, i, arr->Get(i), type))) {
            char errorMsg[60];
            sprintf(errorMsg, "Invalid value for column %d, type should be : %d", i, type);
            SWIG_V8_Raise(errorMsg);
            SWIG_fail;
        }
    }
}

/*
* typemap for Container::get()
*/
%typemap(in, fragment = "convertToRowKeyFieldWithType") (griddb::Field* keyFields)(griddb::Field field) {
    $1 = &field;
    if ($input->IsNull() || $input->IsUndefined()) {
%#if GS_COMPATIBILITY_SUPPORT_3_5
        $1->type = GS_TYPE_NULL;
%#else
        SWIG_V8_Raise("Not support for NULL");
        SWIG_fail;
%#endif
    } else {
        GSType* typeList = arg1->getGSTypeList();
        GSType type = typeList[0];
        if (!convertToRowKeyFieldWithType(*$1, $input, type)) {
            SWIG_V8_Raise("Can not convert to row field");
            SWIG_fail;
        }
    }
}

%typemap(in, numinputs = 0) (GSRow *rowdata) {
    $1 = NULL;
}

/**
 * Support convert data from GSRow* row to javascript data
 */
%fragment("getRowFields", "header", fragment = "convertTimestampToObject") {
static bool getRowFields(GSRow* row, int columnCount, GSType* typeList, bool timestampOutput, int* columnError, 
        GSType* fieldTypeError, v8::Local<v8::Array> outList) {
    GSResult ret;
    GSValue mValue;
    bool retVal = true;
    for (int i = 0; i < columnCount; i++) {
        //Check NULL value
        GSBool nullValue;
%#if GS_COMPATIBILITY_SUPPORT_3_5
        ret = gsGetRowFieldNull(row, (int32_t) i, &nullValue);
        if (ret != GS_RESULT_OK) {
            *columnError = i;
            retVal = false;
            *fieldTypeError = GS_TYPE_NULL;
            return retVal;
        }
        if (nullValue) {
            outList->Set(i, SWIGV8_NULL());
            continue;
        }
%#endif
        switch(typeList[i]) {
            case GS_TYPE_LONG: {
                int64_t longValue;
                ret = gsGetRowFieldAsLong(row, (int32_t) i, &longValue);
                outList->Set(i, SWIGV8_NUMBER_NEW(longValue));
                break;
            }
            case GS_TYPE_STRING: {
                GSChar* stringValue;
                ret = gsGetRowFieldAsString(row, (int32_t) i, (const GSChar **)&stringValue);
                outList->Set(i, SWIGV8_STRING_NEW(stringValue));
                break;
            }
            case GS_TYPE_BLOB: {
                GSBlob blobValue;
                ret = gsGetRowFieldAsBlob(row, (int32_t) i, &blobValue);
                outList->Set(i, Nan::CopyBuffer((char *)blobValue.data, blobValue.size).ToLocalChecked());
                break;
            }
            case GS_TYPE_BOOL: {
                GSBool boolValue;
                ret = gsGetRowFieldAsBool(row, (int32_t) i, &boolValue);
                outList->Set(i, SWIGV8_BOOLEAN_NEW((bool)boolValue));
                break;
            }
            case GS_TYPE_INTEGER: {
                int32_t intValue;
                ret = gsGetRowFieldAsInteger(row, (int32_t) i, &intValue);
                outList->Set(i, SWIGV8_INT32_NEW(intValue));
                break;
            }
            case GS_TYPE_FLOAT: {
                float floatValue;
                ret = gsGetRowFieldAsFloat(row, (int32_t) i, &floatValue);
                outList->Set(i, SWIGV8_NUMBER_NEW(floatValue));
                break;
            }
            case GS_TYPE_DOUBLE: {
                double doubleValue;
                ret = gsGetRowFieldAsDouble(row, (int32_t) i, &doubleValue);
                outList->Set(i, SWIGV8_NUMBER_NEW(doubleValue));
                break;
            }
            case GS_TYPE_TIMESTAMP: {
                GSTimestamp timestampValue;
                ret = gsGetRowFieldAsTimestamp(row, (int32_t) i, &timestampValue);
                outList->Set(i, convertTimestampToObject(&timestampValue, timestampOutput));
                break;
            }
            case GS_TYPE_BYTE: {
                int8_t byteValue;
                ret = gsGetRowFieldAsByte(row, (int32_t) i, &byteValue);
                outList->Set(i, SWIGV8_INT32_NEW(byteValue));
                break;
            }
            case GS_TYPE_SHORT: {
                int16_t shortValue;
                ret = gsGetRowFieldAsShort(row, (int32_t) i, &shortValue);
                outList->Set(i, SWIGV8_INT32_NEW(shortValue));
                break;
            }
            case GS_TYPE_GEOMETRY: {
                GSChar* geoValue;
                ret = gsGetRowFieldAsGeometry(row, (int32_t) i, (const GSChar **)&geoValue);
                outList->Set(i, SWIGV8_STRING_NEW(geoValue));
                break;
            }
            case GS_TYPE_INTEGER_ARRAY: {
                int32_t* intArr;
                size_t size;
                ret = gsGetRowFieldAsIntegerArray (row, (int32_t) i, (const int32_t **)&intArr, &size);
                v8::Local<v8::Array> list = SWIGV8_ARRAY_NEW();
                for (int j = 0; j < size; j++) {
                    list->Set(j, SWIG_From_int(intArr[j]));
                }
                outList->Set(i, list);
                break;
            }
            case GS_TYPE_STRING_ARRAY: {
                GSChar** stringArrVal;
                size_t size;
                ret = gsGetRowFieldAsStringArray (row, (int32_t) i, ( const GSChar *const **)&stringArrVal, &size);
                v8::Local<v8::Array> list = SWIGV8_ARRAY_NEW();
                for (int j = 0; j < size; j++) {
                    list->Set(j, SWIGV8_STRING_NEW((GSChar *)stringArrVal[j]));
                }
                outList->Set(i, list);
                break;
            }
            case GS_TYPE_BOOL_ARRAY: {
                GSBool* boolArr;
                size_t size;
                ret = gsGetRowFieldAsBoolArray(row, (int32_t) i, (const GSBool **)&boolArr, &size);
                v8::Local<v8::Array> list = SWIGV8_ARRAY_NEW();
                for (int j = 0; j < size; j++) {
                    list->Set(j, SWIG_From_bool(boolArr[j]));
                }
                outList->Set(i, list);
                break;
            }
            case GS_TYPE_BYTE_ARRAY: {
                int8_t* byteArr;
                size_t size;
                ret = gsGetRowFieldAsByteArray(row, (int32_t) i, (const int8_t **)&byteArr, &size);
                v8::Local<v8::Array> list = SWIGV8_ARRAY_NEW();
                for (int j = 0; j < size; j++) {
                    list->Set(j, SWIG_From_int(byteArr[j]));
                }
                outList->Set(i, list);
                break;
            }
            case GS_TYPE_SHORT_ARRAY: {
                int16_t* shortArr;
                size_t size;
                ret = gsGetRowFieldAsShortArray(row, (int32_t) i, (const int16_t **)&shortArr, &size);
                v8::Local<v8::Array> list = SWIGV8_ARRAY_NEW();
                for (int j = 0; j < size; j++) {
                    list->Set(j, SWIG_From_int(shortArr[j]));
                }
                outList->Set(i, list);
                break;
            }
            case GS_TYPE_LONG_ARRAY: {
                int64_t* longArr;
                size_t size;
                ret = gsGetRowFieldAsLongArray(row, (int32_t) i, (const int64_t **)&longArr, &size);
                v8::Local<v8::Array> list = SWIGV8_ARRAY_NEW();
                for (int j = 0; j < size; j++) {
                    list->Set(j, SWIGV8_NUMBER_NEW(longArr[j]));
                }
                outList->Set(i, list);
                break;
            }
            case GS_TYPE_FLOAT_ARRAY: {
                float* floatArr;
                size_t size;
                ret = gsGetRowFieldAsFloatArray(row, (int32_t) i, (const float **)&floatArr, &size);
                v8::Local<v8::Array> list = SWIGV8_ARRAY_NEW();
                for (int j = 0; j < size; j++) {
                    list->Set(j, SWIGV8_NUMBER_NEW(((float *)floatArr)[j]));
                }
                outList->Set(i, list);
                break;
            }
            case GS_TYPE_DOUBLE_ARRAY: {
                double* doubleArr;
                size_t size;
                ret = gsGetRowFieldAsDoubleArray(row, (int32_t) i, (const double **)&doubleArr, &size);
                v8::Local<v8::Array> list = SWIGV8_ARRAY_NEW();
                for (int j = 0; j < size; j++) {
                    list->Set(j, SWIGV8_NUMBER_NEW(((double *)doubleArr)[j]));
                }
                outList->Set(i, list);
                break;
            }
            case GS_TYPE_TIMESTAMP_ARRAY: {
                GSTimestamp* timestampArr;
                size_t size;
                ret = gsGetRowFieldAsTimestampArray(row, (int32_t) i, (const GSTimestamp **)&timestampArr, &size);
                v8::Local<v8::Array> list = SWIGV8_ARRAY_NEW();
                for (int j = 0; j < size; j++) {
                    list->Set(j, convertTimestampToObject((GSTimestamp*)&(timestampArr[j]), timestampOutput));
                }
                outList->Set(i, list);
                break;
            }
            default: {
                // NOT OK
                ret = -1;
                break;
            }
        }
        if (ret != GS_RESULT_OK) {
            *columnError = i;
            *fieldTypeError = typeList[i];
            retVal = false;
            return retVal;
        }
    }
    return retVal;
}
}

%typemap(argout, fragment = "getRowFields") (GSRow *rowdata) (v8::Local<v8::Array> obj, v8::Handle<v8::Value> val) {
    if (result == GS_FALSE) {
        $result = SWIGV8_NULL();
    } else {
        GSRow* row = arg1->getGSRowPtr();
        obj = SWIGV8_ARRAY_NEW();
        bool retVal;
        int errorColumn;
        GSType errorType;
        retVal = getRowFields(row, arg1->getColumnCount(), arg1->getGSTypeList(), arg1->timestamp_output_with_float, &errorColumn, &errorType, obj);
        if (retVal == false) {
            char errorMsg[60];
            sprintf(errorMsg, "Can't get data for field %d with type %d", errorColumn, errorType);
            SWIG_V8_Raise(errorMsg);
            SWIG_fail;
        }
        $result = obj;
    }
}

/**
 * Typemaps for Store.multi_put
 */
%typemap(in, fragment = "convertToRowKeyFieldWithType", fragment = "SWIG_AsCharPtrAndSize", fragment = "cleanString"
        , fragment = "freeargStoreMultiPut") (GSRow*** listRow, const int *listRowContainerCount, const char ** listContainerName, size_t containerCount)
(v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, v8::Local<v8::Array> arr, int res = 0, v8::Local<v8::Array> rowArr,
size_t sizeTmp = 0, int* alloc = 0, char* v = 0) {
    if (!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    $1 = NULL;
    $2 = NULL;
    $3 = NULL;
    $4 = 0;
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    $4 = (size_t) keys->Length();
    griddb::Container* tmpContainer;

    if ($4 > 0) {
        $1 = new GSRow**[$4];
        $2 = (int*) malloc($4 * sizeof(int));
        $3 = (char **) malloc($4 * sizeof(char*));
        alloc = (int*) malloc($4*sizeof(int));
        if ($1 == NULL || $2 == NULL || $3 == NULL || alloc == NULL) {
            freeargStoreMultiPut($1, $2, $3, $4, alloc);
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        memset(alloc, 0x0, $4*sizeof(int));

        for (int i = 0; i < $4; i++) {
            // Get container name
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &v, &sizeTmp, &alloc[i]);
            if (!SWIG_IsOK(res)) {
                freeargStoreMultiPut($1, $2, $3, i, alloc);
                %variable_fail(res, "String", "containerName");
            }
            if (v) {
                $3[i] = strdup(v);
                cleanString(v, alloc[i]);
            } else {
                $3[i] = NULL;
            }
            // Get row
            if (!(obj->Get(keys->Get(i)))->IsArray()) {
                freeargStoreMultiPut($1, $2, $3, i, alloc);
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
            for (int j = 0; j < $2[i]; j++) {
                ret = gsCreateRowByContainer(tmpContainer->getGSContainerPtr(), &$1[i][j]);
                rowArr = v8::Local<v8::Array>::Cast(arr->Get(j));
                int rowLen = (int) rowArr->Length();
                int k;
                for (k = 0; k < rowLen; k++) {
                    if (!(convertToFieldWithType($1[i][j], k, rowArr->Get(k), typeArr[k]))) {
                        char errorMsg[60];
                        sprintf(errorMsg, "Invalid value for column %d, type should be : %d", k, typeArr[k]);
                        delete containerInfoTmp;
                        free((void *) typeArr);
                        freeargStoreMultiPut($1, $2, $3, i, alloc);
                        SWIG_V8_Raise(errorMsg);
                        SWIG_fail;
                    }
                }
            }
        }
    }
}

%typemap(freearg, fragment = "freeargStoreMultiPut") (GSRow*** listRow, const int *listRowContainerCount, char ** listContainerName, size_t containerCount) {
    freeargStoreMultiPut($1, $2, $3, $4, alloc$argnum);
}

%fragment("freeargStoreMultiPut", "header") {
    //SWIG does not include freearg in fail: label (not like Python, so we need this function)
static void freeargStoreMultiPut(GSRow*** listRow, const int *listRowContainerCount, char ** listContainerName, size_t containerCount, int* alloc) {
    if (listRow) {
        for (int i = 0; i < containerCount; i++) {
            if (listRow[i]) {
                for (int j = 0; j < listRowContainerCount[i]; j++) {
                    gsCloseRow(&listRow[i][j]);
                }
                delete [] listRow[i];
                listRow[i] = NULL;
            }
        }
        delete [] listRow;
        listRow = NULL;
    }

    if (listRowContainerCount) delete listRowContainerCount;
    if (listContainerName) {
        for (int i = 0; i < containerCount; i++) {
            if (listContainerName[i]) {
                free((void*)listContainerName[i]);
                listContainerName[i] = NULL;
            }
        }
        free((void *) listContainerName);
    }
    if (alloc) {
        free((void *) alloc);
    }
}
}

/**
* Typemaps input for Store.multi_get() function
*/
%typemap(in, fragment = "freeargStoreMultiGet") (const GSRowKeyPredicateEntry *const * predicateList, size_t predicateCount
        , GSContainerRowEntry **entryList, size_t* containerCount, int **colNumList, GSType*** typeList, int **orderFromInput)
        (v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, GSRowKeyPredicateEntry* pList,
        griddb::RowKeyPredicate *vpredicate, int res = 0, size_t size = 0, int* alloc = 0, char* v = 0, 
        GSContainerRowEntry *tmpEntryList, size_t tmpContainerCount, int *tmpcolNumList, GSType** tmpTypeList, int *tmpOrderFromInput) {
    if (!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    $1 = NULL;
    $2 = (int) keys->Length();
    $3 = &tmpEntryList;
    $4 = &tmpContainerCount;
    $5 = &tmpcolNumList;
    $6 = &tmpTypeList;
    $7 = &tmpOrderFromInput;
    if ($2 > 0) {
        pList = (GSRowKeyPredicateEntry*) malloc($2*sizeof(GSRowKeyPredicateEntry));
        if (pList == NULL) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        $1 = &pList;
        alloc = (int*) malloc($2 * 2 * sizeof(int));
        if (alloc == NULL) {
            freeargStoreMultiGet($1, $2, $3, $4, $5, $6, $7, alloc);
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        memset(alloc, 0, $2 * 2 * sizeof(int));
        for (int i = 0; i < $2; i++) {
            GSRowKeyPredicateEntry *predicateEntry = &pList[i];
            // Get container name
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &v, &size, &alloc[i]);
            if (!SWIG_IsOK(res)) {
                freeargStoreMultiGet($1, $2, $3, $4, $5, $6, $7, alloc);
                %variable_fail(res, "String", "containerName");
            }
            predicateEntry->containerName = v;

            // Get predicate
            res = SWIG_ConvertPtr((obj->Get(keys->Get(i))), (void**)&vpredicate, $descriptor(griddb::RowKeyPredicate*), 0);
            if (!SWIG_IsOK(res)) {
                freeargStoreMultiGet($1, $2, $3, $4, $5, $6, $7, alloc);
                SWIG_V8_Raise("Convert RowKeyPredicate pointer failed");
                SWIG_fail;
            }
            predicateEntry->predicate = vpredicate->gs_ptr();
        }
    }
}

%typemap(argout, fragment = "getRowFields", fragment = "freeargStoreMultiGet") 
        (const GSRowKeyPredicateEntry *const * predicateList, size_t predicateCount, 
        GSContainerRowEntry **entryList, size_t* containerCount, int **colNumList, GSType*** typeList, int **orderFromInput) 
        (v8::Local<v8::Object> obj, v8::Local<v8::Array> arr, v8::Local<v8::Array> rowArr, 
        v8::Handle<v8::String> key, v8::Handle<v8::Value> value, GSRow* row) {
    obj = SWIGV8_OBJECT_NEW();
    int numContainer = (int) *$4;
    bool retVal;
    int errorColumn;
    GSType errorType;
    for (int i = 0; i < numContainer; i++) {
        key = SWIGV8_STRING_NEW2((*$3)[i].containerName, strlen((char*)(*$3)[i].containerName));
        arr = SWIGV8_ARRAY_NEW();
        for (int j = 0; j < (*$3)[i].rowCount; j++) {
            row = (GSRow*)(*$3)[i].rowList[j];
            rowArr = SWIGV8_ARRAY_NEW();
            retVal = getRowFields(row, (*$5)[i], (*$6)[i], arg1->timestamp_output_with_float, &errorColumn, &errorType, rowArr);
            if (retVal == false) {
                freeargStoreMultiGet($1, $2, $3, $4, $5, $6, $7, alloc$argnum);
                char errorMsg[60];
                sprintf(errorMsg, "Can't get data for field %d with type %d", errorColumn, errorType);
                SWIG_V8_Raise(errorMsg);
                SWIG_fail;
            }
            arr->Set(j, rowArr);
        }
        obj->Set(key, arr);
    }
    $result = obj;
}

%typemap(freearg, fragment = "freeargStoreMultiGet") (const GSRowKeyPredicateEntry *const * predicateList, size_t predicateCount ,
        GSContainerRowEntry **entryList, size_t* containerCount, int **colNumList, GSType*** typeList, int **orderFromInput) {
    freeargStoreMultiGet($1, $2, $3, $4, $5, $6, $7, alloc$argnum);
}

%fragment("freeargStoreMultiGet", "header") {
    //SWIG does not include freearg in fail: label (not like Python, so we need this function)
static void freeargStoreMultiGet(const GSRowKeyPredicateEntry *const * predicateList, size_t predicateCount, 
        GSContainerRowEntry **entryList, size_t* containerCount, int **colNumList, GSType*** typeList, int **orderFromInput, int* alloc) {
    int i;
    GSRowKeyPredicateEntry* pList;
    if (predicateList && *predicateList) {
        pList = (GSRowKeyPredicateEntry*) *predicateList;
        for (i = 0; i < predicateCount; i++) {
            cleanString((*predicateList)[i].containerName, alloc[i]);
        }
        if (pList) {
            free(pList);
        }
    }
    if (alloc) {
        free(alloc);
    }

    if (*colNumList) {
        delete [] *colNumList;
    }
    if (*typeList) {
        for (int j = 0; j < (int) predicateCount; j++) {
            if ((*typeList)[j]) {
                free ((void*) (*typeList)[j]);
            }
        }
        delete [] (*typeList);
    }
    if (entryList) {
        GSRow* row;
        for (int i = 0; i < *containerCount; i++) {
            for (int j = 0; j < (*entryList)[i].rowCount; j++) {
                row = (GSRow*)(*entryList)[i].rowList[j];
                gsCloseRow(&row);
            }
        }
    }
    if (*orderFromInput) {
        delete [] *orderFromInput;
    }
}
}

/**
 * Create typemap for RowKeyPredicate.set_range
 */
%typemap(in, fragment = "convertToRowKeyFieldWithType") (griddb::Field* startKey)(griddb::Field field) {
    $1 = &field;
    if ($1 == NULL) {
        SWIG_V8_Raise("Memory allocation error");
        SWIG_fail;
    }
    GSType type = arg1->get_key_type();
    if (!(convertToRowKeyFieldWithType(*$1, $input, type))) {
        %variable_fail(1, "String", "Can not create row based on input");
    }
}

%typemap(in, fragment = "convertToRowKeyFieldWithType") (griddb::Field* finishKey)(griddb::Field field) {
    $1 = &field;
    if ($1 == NULL) {
        SWIG_V8_Raise("Memory allocation error");
        SWIG_fail;
    }
    GSType type = arg1->get_key_type();
    if (!(convertToRowKeyFieldWithType(*$1, $input, type))) {
        %variable_fail(1, "String", "Can not create row based on input");
    }
}

/**
 * Typemap for RowKeyPredicate.get_range
 */
%typemap(in, numinputs = 0) (griddb::Field* startField, griddb::Field* finishField) (griddb::Field startKeyTmp, griddb::Field finishKeyTmp) {
    $1 = &startKeyTmp;
    $2 = &finishKeyTmp;
}

%typemap(argout, fragment = "convertFieldToObject") (griddb::Field* startField, griddb::Field* finishField) {
    v8::Local<v8::Array> arr;
    arr = SWIGV8_ARRAY_NEW();
    arr->Set(0, convertFieldToObject(&$1->value, $1->type, arg1->timestamp_output_with_float));
    arr->Set(1, convertFieldToObject(&$2->value, $2->type, arg1->timestamp_output_with_float));
    $result = arr;
}

/**
 * Typemap for RowKeyPredicate.set_distinct_keys
 */
%typemap(in, fragment = "convertToRowKeyFieldWithType") (const griddb::Field *keys, size_t keyCount) {
    if (!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }
    v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast($input);
    $2 = (int)arr->Length();
    $1 = NULL;
    if ($2 > 0) {
        $1 = new griddb::Field[$2];
        if ($1 == NULL) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        GSType type = arg1->get_key_type();
        for (int i = 0; i < $2; i++) {
            if (!(convertToRowKeyFieldWithType($1[i], arr->Get(i), type))) {
                SWIG_V8_Raise("Can not create row based on input");
                SWIG_fail;
            }
        }
    }
}

%typemap(freearg) (const griddb::Field *keys, size_t keyCount) {
    if ($1) {
        delete [] $1;
    }
}


/**
* Typemaps output for RowKeyPredicate.get_distinct_keys
*/
%typemap(in, numinputs = 0) (griddb::Field **keys, size_t* keyCount) (griddb::Field *keys1, size_t keyCount1) {
    $1 = &keys1;
    $2 = &keyCount1;
}

%typemap(argout, numinputs = 0, fragment = "convertFieldToObject") (griddb::Field **keys, size_t* keyCount) {
    v8::Local<v8::Array> obj;
    obj = SWIGV8_ARRAY_NEW();
    for (int i = 0; i < keyCount1$argnum; i++) {
        v8::Handle<v8::Value> value = convertFieldToObject(&keys1$argnum[i].value, keys1$argnum[i].type, arg1->timestamp_output_with_float);
        obj->Set(i, value);
    }
    $result = obj;
}

/**
 * Typemap for Container::multi_put
 */
%typemap(in, fragment = "convertToFieldWithType", fragment = "freeargContainerMultiPut") (GSRow** listRowdata, int rowCount) {
    if (!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }

    v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast($input);
    $2 = (size_t)arr->Length();

    if ($2 > 0) {
        GSContainer *mContainer = arg1->getGSContainerPtr();
        GSType* typeList = arg1->getGSTypeList();
        $1 = new GSRow*[$2];
        int length;
        for (int i = 0; i < $2; i++) {
            v8::Local<v8::Array> fieldArr = v8::Local<v8::Array>::Cast(arr->Get(i));
            length = (int)fieldArr->Length();
            if (length != arg1->getColumnCount()) {
                freeargContainerMultiPut($1, i);
                SWIG_V8_Raise("Num row is different with container info");
                SWIG_fail;
            }
            GSResult ret = gsCreateRowByContainer(mContainer, &$1[i]);
            if (ret != GS_RESULT_OK) {
                freeargContainerMultiPut($1, i);
                SWIG_V8_Raise("Can't create GSRow");
                SWIG_fail;
            }
            for (int k = 0; k < length; k++) {
                GSType type = typeList[k];
                if (!(convertToFieldWithType($1[i], k, fieldArr->Get(k), type))) {
                    char errorMsg[200];
                    sprintf(errorMsg, "Invalid value for row %d, column %d, type should be : %d", i, k, type);
                    freeargContainerMultiPut($1, i + 1);
                    SWIG_V8_Raise(errorMsg);
                    SWIG_fail;
                }
            }
        }
    }
}

%typemap(freearg, fragment = "freeargContainerMultiPut") (GSRow** listRowdata, int rowCount) {
    freeargContainerMultiPut($1, $2);
}

%fragment("freeargContainerMultiPut", "header") {
    //SWIG does not include freearg in fail: label (not like Python, so we need this function)
static void freeargContainerMultiPut(GSRow** listRowdata, int rowCount) {
    if (listRowdata) {
        for (int rowNum = 0; rowNum < rowCount; rowNum++) {
            gsCloseRow(&listRowdata[rowNum]);
        }
        delete [] listRowdata;
    }
}
}

/**
 * Typemap for QueryAnalysisEntry.get()
 */
%typemap(in, numinputs = 0) (GSQueryAnalysisEntry* queryAnalysis) (GSQueryAnalysisEntry queryAnalysis1) {
    queryAnalysis1 = GS_QUERY_ANALYSIS_ENTRY_INITIALIZER;
    $1 = &queryAnalysis1;
}

%typemap(argout) (GSQueryAnalysisEntry* queryAnalysis) {
    v8::Local<v8::Array> obj;
    obj = SWIGV8_ARRAY_NEW();
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
%typemap(in, numinputs = 0) (GSRowSetType* type, bool* hasNextRow,
        griddb::QueryAnalysisEntry** queryAnalysis, griddb::AggregationResult** aggResult)
    (GSRowSetType typeTmp, bool hasNextRowTmp,
    griddb::QueryAnalysisEntry* queryAnalysisTmp, griddb::AggregationResult* aggResultTmp) {
    $1 = &typeTmp;
    hasNextRowTmp = true;
    $2 = &hasNextRowTmp;
    $3 = &queryAnalysisTmp;
    $4 = &aggResultTmp;
}
%typemap(argout) (GSRowSetType* type, bool* hasNextRow,
        griddb::QueryAnalysisEntry** queryAnalysis, griddb::AggregationResult** aggResult) 
    (v8::Local<v8::Array> obj, v8::Handle<v8::Value> value) {
    GSRow* row;
    switch (typeTmp$argnum) {
        case GS_ROW_SET_CONTAINER_ROWS: {
            bool retVal;
            int errorColumn;
            GSType errorType;
            if (hasNextRowTmp$argnum == false) {
                $result = SWIGV8_NULL();
            } else {
                row = arg1->getGSRowPtr();
                obj = SWIGV8_ARRAY_NEW();
                if (obj->IsNull()) {
                    SWIG_V8_Raise("Memory allocation error");
                    SWIG_fail;
                }
                retVal = getRowFields(row, arg1->getColumnCount(), arg1->getGSTypeList(), arg1->timestamp_output_with_float, &errorColumn, &errorType, obj);
                if (retVal == false) {
                    char errorMsg[60];
                    sprintf(errorMsg, "Can't get data for field %d with type %d", errorColumn, errorType);
                    SWIG_V8_Raise(errorMsg);
                    SWIG_fail;
                }
                $result = obj;
            }
            break;
        }
        case GS_ROW_SET_AGGREGATION_RESULT:
            if (hasNextRowTmp$argnum == true) {
                value = SWIG_V8_NewPointerObj((void *)aggResultTmp$argnum, $descriptor(griddb::AggregationResult *), SWIG_POINTER_OWN);
                $result = value;
            } else {
                $result = SWIGV8_NULL();
            }
            break;
        case GS_ROW_SET_QUERY_ANALYSIS:
            if (hasNextRowTmp$argnum == true) {
                value = SWIG_V8_NewPointerObj((void *)queryAnalysisTmp$argnum, $descriptor(griddb::QueryAnalysisEntry *), SWIG_POINTER_OWN);
                $result = value;
            } else {
                $result = SWIGV8_NULL();
            }
            break;
        default:
            SWIG_V8_Raise("Invalid Rowset type");
            SWIG_fail;
            break;
    }
}

//attribute ContainerInfo::columnInfoList
%typemap(in, fragment = "freeargColumnInfoList") (ColumnInfoList*) 
        (v8::Local<v8::Array> arr, v8::Local<v8::Array> colInfo, v8::Local<v8::Array> keys, size_t sizeTmp = 0, int* alloc = 0, int res, char* v = 0, ColumnInfoList infolist) {

    if (!$input->IsArray()) {
        SWIG_V8_Raise("Expected array as input");
        SWIG_fail;
    }
    v8::Local<v8::Array> arr = v8::Local<v8::Array>::Cast($input);
    size_t len = (size_t)arr->Length();
    GSColumnInfo* containerInfo;
    $1 = &infolist;
    if (len) {
        containerInfo = (GSColumnInfo*) malloc(len * sizeof(GSColumnInfo));
        if (containerInfo == NULL ) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        alloc = (int*) malloc(len*sizeof(int));
        if (alloc == NULL) {
            free((void*) containerInfo);
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        $1->columnInfo = containerInfo;
        $1->size = len;
        memset(containerInfo, 0x0, len*sizeof(GSColumnInfo));
        memset(alloc, 0x0, len*sizeof(int));

        for (int i = 0; i < len; i++) {
            if (!(arr->Get(i))->IsArray()) {
                freeargColumnInfoList($1, alloc);
                SWIG_V8_Raise("Expected array property as ColumnInfo element");
                SWIG_fail;
            }

            colInfo = v8::Local<v8::Array>::Cast(arr->Get(i));
            if (colInfo->Length() < 2) {
                freeargColumnInfoList($1, alloc);
                SWIG_V8_Raise("Expected at least two elements for ColumnInfo property");
                SWIG_fail;
            }
            v8::Local<v8::Value> key = colInfo->Get(0);
            v8::Local<v8::Value> value = colInfo->Get(1);

            res = SWIG_AsCharPtrAndSize(key, &v, &sizeTmp, &alloc[i]);
            if (!SWIG_IsOK(res)) {
                freeargColumnInfoList($1, alloc);
                %variable_fail(res, "String", "Column name");
            }

            if (!value->IsNumber()) {
                freeargColumnInfoList($1, alloc);
                SWIG_V8_Raise("Expected Integer as type of Column type");
                SWIG_fail;
            }

            containerInfo[i].name = v;
            containerInfo[i].type = value->Uint32Value();

            if (colInfo->Length() == 3) {
%#if GS_COMPATIBILITY_SUPPORT_3_5
                v8::Local<v8::Value> options = colInfo->Get(2);

                if (!options->IsNumber()) {
                    freeargColumnInfoList($1, alloc);
                    SWIG_V8_Raise("Expected Integer as type of Column options");
                    SWIG_fail;
                }

                containerInfo[i].options = options->Uint32Value();
%#else
                freeargColumnInfoList($1, alloc);
                SWIG_V8_Raise("Expected two elements for ColumnInfo property");
                SWIG_fail;
%#endif
            }
        }
    }
}

%typemap(freearg, fragment = "cleanString", fragment = "freeargColumnInfoList") (ColumnInfoList*) {
    freeargColumnInfoList($1, alloc$argnum);
}

%fragment("freeargColumnInfoList", "header", fragment = "cleanString") {
    //SWIG does not include freearg in fail: label (not like Python, so we need this function)
static void freeargColumnInfoList(ColumnInfoList* infoList, int* alloc) {
    size_t len = infoList->size;
    if (infoList->columnInfo) {
        if (alloc) {
            for (int i = 0; i < len; i++) {
                cleanString(infoList->columnInfo[i].name, alloc[i]);
            }
            free(alloc);
        }
        free ((void *)infoList->columnInfo);
    }
}
}

%typemap(out) (ColumnInfoList*) {
    v8::Local<v8::Array> obj;
    size_t len = $1->size;
    if (len > 0) {
        obj = SWIGV8_ARRAY_NEW();
        if (obj->IsNull()) {
            SWIG_V8_Raise("Memory allocation error");
            SWIG_fail;
        }
        for (int i = 0; i < len; i++) {
            v8::Local<v8::Array> prop;
            prop = SWIGV8_ARRAY_NEW();
            v8::Handle<v8::String> str = SWIGV8_STRING_NEW2($1->columnInfo[i].name, strlen((char*)$1->columnInfo[i].name));
            prop->Set(0, str);
            prop->Set(1, SWIGV8_NUMBER_NEW($1->columnInfo[i].type));
%#if GS_COMPATIBILITY_SUPPORT_3_5
            prop->Set(2, SWIGV8_NUMBER_NEW($1->columnInfo[i].options));
%#endif
            obj->Set(i, prop);
        }
    }
    $result = obj;
}

/**
* Typemaps for create_index()/ drop_index function : support keyword parameter ({"columnName" : str, "indexType" : int, "name" : str})
*/
%typemap(in, fragment = "SWIG_AsCharPtrAndSize", fragment = "cleanString" , fragment = "freeargContainerIndex") (const char* column_name, GSIndexTypeFlags index_type, const char* name)
        (v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, int i, int j, size_t size = 0,size_t size1 = 0, int* alloc = 0, int res,  char* v = 0) {
    char* name;
    if (!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    int len = (int) keys->Length();
    //Create $1, $2, $3 with default value
    $1 = NULL;
    $2 = GS_INDEX_FLAG_DEFAULT;
    $3 = NULL;
    int allocKey;
    int allocValue;
    char errorMsg[60];
    if (len > 0) {
        for (int i = 0; i < len; i++) {
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &name, &size, &allocKey);
            if (!SWIG_IsOK(res)) {
                freeargContainerIndex($1, $3);
                %variable_fail(res, "String", "name");
            }
            if (strcmp(name, "columnName") == 0) {
                if (!obj->Get(keys->Get(i))->IsString()) {
                    sprintf(errorMsg, "Invalid value for property %s", name);
                    cleanString(name, allocKey);
                    freeargContainerIndex($1, $3);
                    SWIG_V8_Raise(errorMsg);
                    SWIG_fail;
                }
                res = SWIG_AsCharPtrAndSize(obj->Get(keys->Get(i)), &v, &size1, &allocValue);
                if (!SWIG_IsOK(res)) {
                    freeargContainerIndex($1, $3);
                    %variable_fail(res, "String", "value");
                }
                if (v) {
                    $1 = strdup(v);
                    cleanString(v, allocValue);
                }
            } else if (strcmp(name, "indexType") == 0) {
                if (!obj->Get(keys->Get(i))->IsInt32()) {
                    sprintf(errorMsg, "Invalid value for property %s", name);
                    cleanString(name, allocKey);
                    freeargContainerIndex($1, $3);
                    SWIG_V8_Raise(errorMsg);
                    SWIG_fail;
                }
                $2 = obj->Get(keys->Get(i))->IntegerValue();
            } else if (strcmp(name, "name") == 0) {
                if (!obj->Get(keys->Get(i))->IsString()) {
                    sprintf(errorMsg, "Invalid value for property %s", name);
                    cleanString(name, allocKey);
                    freeargContainerIndex($1, $3);
                    SWIG_V8_Raise(errorMsg);
                    SWIG_fail;
                }
                res = SWIG_AsCharPtrAndSize(obj->Get(keys->Get(i)), &v, &size1, &allocValue);
                if (!SWIG_IsOK(res)) {
                    freeargContainerIndex($1, $3);
                    %variable_fail(res, "String", "value");
                }
                if (v) {
                    $3 = strdup(v);
                    cleanString(v, allocValue);
                }
            } else {
                sprintf(errorMsg, "Invalid property %s", name);
                cleanString(name, allocKey);
                freeargContainerIndex($1, $3);
                SWIG_V8_Raise(errorMsg);
                SWIG_fail;
            }
            cleanString(name, allocKey);
        }
    }
}

%typemap(freearg, fragment = "freeargContainerIndex") (const char* column_name, GSIndexTypeFlags index_type, const char* name) {
    freeargContainerIndex($1, $3);
}

%fragment("freeargContainerIndex", "header") {
    //SWIG does not include freearg in fail: label (not like Python, so we need this function)
static void freeargContainerIndex(const char* column_name, const char* name) {
    if (column_name) {
        free((void*) column_name);
    }
    if (name) {
        free((void*) name);
    }
}
}

/**
* Typemaps for set_fetch_options() : support keyword parameter ({"limit" : int})
*/
%typemap(in, fragment = "SWIG_AsCharPtrAndSize") (int limit, bool partial) 
        (v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, int i, int j, size_t size = 0, int* alloc = 0, int res) {
    char* name;
    if (!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    int len = (int) keys->Length();
    //Create $1, $2 with default value
    $1 = -1;
    $2 = false;
    int allocKey;
    char errorMsg[60];
    if (len > 0) {
        for (int i = 0; i < len; i++) {
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &name, &size, &allocKey);
            if (!SWIG_IsOK(res)) {
                %variable_fail(res, "String", "name");
            }
            if (strcmp(name, "limit") == 0) {
                if (!obj->Get(keys->Get(i))->IsInt32()) {
                    sprintf(errorMsg, "Invalid value for property %s", name);
                    SWIG_V8_Raise(errorMsg);
                    cleanString(name, allocKey);
                    SWIG_fail;
                }
                $1 = obj->Get(keys->Get(i))->IntegerValue();
            } else {
                sprintf(errorMsg, "Invalid property %s", name);
                cleanString(name, allocKey);
                SWIG_V8_Raise(errorMsg);
                SWIG_fail;
            }
            cleanString(name, allocKey);
        }
    }
}

/**
* Typemaps for ContainerInfo : support keyword parameter ({"name" : str, "columnInfoList" : array, "type" : str, 'rowKey':boolean})
*/
%typemap(in, fragment = "SWIG_AsCharPtrAndSize", fragment = "cleanString", fragment = "freeargContainerInfo") (const GSChar* name, const GSColumnInfo* props, 
        int propsCount, GSContainerType type, bool row_key, griddb::ExpirationInfo* expiration)
        (v8::Local<v8::Object> obj, v8::Local<v8::Array> keys, int i, int j, size_t size = 0,size_t size1 = 0, int* alloc = 0, int res,  char* v = 0) {
    char* name;
    if (!$input->IsObject()) {
        SWIG_V8_Raise("Expected object property as input");
        SWIG_fail;
    }
    obj = $input->ToObject();
    keys = obj->GetOwnPropertyNames();
    int len = (int) keys->Length();
    //Create $1, $2, $3, $3, $4, $5, $6 with default value
    $1 = NULL;
    $2 = NULL;
    $3 = 0;
    $4 = GS_CONTAINER_COLLECTION;
    $5 = NULL;
    $6 = NULL;
    int allocKey;
    int allocValue;
    char errorMsg[60];
    v8::Local<v8::Array> arr;
    v8::Local<v8::Array> colInfo;
    bool boolVal, vbool;
    griddb::ExpirationInfo* expiration;
    if (len > 0) {
        for (int i = 0; i < len; i++) {
            res = SWIG_AsCharPtrAndSize(keys->Get(i), &name, &size, &allocKey);
            if (!SWIG_IsOK(res)) {
                freeargContainerInfo($1, $2, $3, alloc);
                %variable_fail(res, "String", "name");
            }
            if (strcmp(name, "name") == 0) {
                if (!obj->Get(keys->Get(i))->IsString()) {
                    freeargContainerInfo($1, $2, $3, alloc);
                    sprintf(errorMsg, "Invalid value for property %s", name);
                    SWIG_V8_Raise(errorMsg);
                    cleanString(name, allocKey);
                    SWIG_fail;
                }
                res = SWIG_AsCharPtrAndSize(obj->Get(keys->Get(i)), &v, &size1, &allocValue);
                if (!SWIG_IsOK(res)) {
                    freeargContainerInfo($1, $2, $3, alloc);
                    sprintf(errorMsg, "Memory allocation error for property %s", name);
                    SWIG_V8_Raise(errorMsg);
                    cleanString(name, allocKey);
                    SWIG_fail;
                }
                if (v) {
                    $1 = strdup(v);
                    cleanString(v, allocValue);
                }
            } else if (strcmp(name, "columnInfoList") == 0) {
                if (!obj->Get(keys->Get(i))->IsArray()) {
                    freeargContainerInfo($1, $2, $3, alloc);
                    sprintf(errorMsg, "Expected array as input for property %s", name);
                    SWIG_V8_Raise(errorMsg);
                    cleanString(name, allocKey);
                    SWIG_fail;
                }
                arr = v8::Local<v8::Array>::Cast(obj->Get(keys->Get(i)));
                $3 = (int) arr->Length();
                    if ($3 > 0) {
                        $2 = (GSColumnInfo *) malloc($3*sizeof(GSColumnInfo));
                        alloc = (int*) malloc($3*sizeof(int));
                        if ($2 == NULL || alloc == NULL) {
                            freeargContainerInfo($1, $2, $3, alloc);
                            SWIG_V8_Raise("Memory allocation error");
                            SWIG_fail;
                        }
                        memset($2, 0x0, $3*sizeof(GSColumnInfo));
                        memset(alloc, 0x0, $3*sizeof(int));

                        for (int j = 0; j < $3; j++) {
                            if (!(arr->Get(j))->IsArray()) {
                                freeargContainerInfo($1, $2, $3, alloc);
                                SWIG_V8_Raise("Expected array property as ColumnInfo element");
                                SWIG_fail;
                            }
                            colInfo = v8::Local<v8::Array>::Cast(arr->Get(j));
                            if ((int)colInfo->Length() < 2 || (int)colInfo->Length() > 3) {
                                freeargContainerInfo($1, $2, $3, alloc);
                                SWIG_V8_Raise("Expected 2 or 3 elements for ColumnInfo property");
                                SWIG_fail;
                            }

                            res = SWIG_AsCharPtrAndSize(colInfo->Get(0), &v, &size, &alloc[j]);
                            if (!SWIG_IsOK(res)) {
                                freeargContainerInfo($1, $2, $3, alloc);
                                %variable_fail(res, "String", "Column name");
                            }

                            if (!colInfo->Get(1)->IsInt32()) {
                                freeargContainerInfo($1, $2, $3, alloc);
                                SWIG_V8_Raise("Expected Integer as type of Column type");
                                SWIG_fail;
                            }
                            $2[j].name = v;
                            $2[j].type = (int) colInfo->Get(1)->Uint32Value();

%#if GS_COMPATIBILITY_SUPPORT_3_5
                            if ((int)colInfo->Length() == 3) {
                                v8::Local<v8::Value> options = colInfo->Get(2);
                                if (!options->IsInt32()) {
                                    freeargContainerInfo($1, $2, $3, alloc);
                                    SWIG_V8_Raise("Expected Integer as type of Column options");
                                    SWIG_fail;
                                }
                                $2[j].options = (int) options->Uint32Value();
                            }
%#endif
                        }
                    }
            } else if (strcmp(name, "type") == 0) {
                if (!obj->Get(keys->Get(i))->IsInt32()) {
                    freeargContainerInfo($1, $2, $3, alloc);
                    sprintf(errorMsg, "Invalid value for property %s", name);
                    SWIG_V8_Raise(errorMsg);
                    cleanString(name, allocKey);
                    SWIG_fail;
                }
                $4 = obj->Get(keys->Get(i))->IntegerValue();
            } else if (strcmp(name, "rowKey") == 0) {
                vbool = convertObjectToBool(obj->Get(keys->Get(i)), &boolVal);
                if (!vbool) {
                    freeargContainerInfo($1, $2, $3, alloc);
                    sprintf(errorMsg, "Invalid value for property %s", name);
                    SWIG_V8_Raise(errorMsg);
                    cleanString(name, allocKey);
                    SWIG_fail;
                }
                $5 = boolVal;
            } else if (strcmp(name, "expiration") == 0) {
                 res = SWIG_ConvertPtr(obj->Get(keys->Get(i)), (void**)&expiration, $descriptor(griddb::ExpirationInfo*), 0 | 0 );
                 if (!SWIG_IsOK(res)) {
                     freeargContainerInfo($1, $2, $3, alloc);
                     sprintf(errorMsg, "Invalid value for property %s", name);
                     SWIG_V8_Raise(errorMsg);
                     cleanString(name, allocKey);
                     SWIG_fail; 
                 }
                 $6 = (griddb::ExpirationInfo *) expiration;
            } else {
                freeargContainerInfo($1, $2, $3, alloc);
                cleanString(name, allocKey);
                SWIG_V8_Raise(errorMsg);
                SWIG_fail;
            }
            cleanString(name, allocKey);
        }
    }
}

%typemap(freearg, fragment = "freeargContainerInfo") (const GSChar* name, const GSColumnInfo* props,
        int propsCount, GSContainerType type, bool row_key, griddb::ExpirationInfo* expiration) {
    freeargContainerInfo($1, $2, $3, alloc$argnum);
}

%fragment("freeargContainerInfo", "header", fragment = "cleanString") {
    //SWIG does not include freearg in fail: label (not like Python, so we need this function)
static void freeargContainerInfo(const GSChar* name, const GSColumnInfo* props,
        int propsCount, int* alloc) {
    if (name) {
        free((void*) name);
    }
    if (props) {
        for (int i = 0; i < propsCount; i++) {
            cleanString(props[i].name, alloc[i]);
        }
        free((void *) props);
    }

    if (alloc) {
        free(alloc);
    }
}
}

/**
 * Support close method : Store.close()
 */
%typemap(in, fragment = "convertObjectToBool") GSBool allRelated{
    bool boolVal;
    v8::Local<v8::Value> obj = $input;
    bool vbool = convertObjectToBool(obj, &boolVal);
    if (!vbool) {
        SWIG_V8_Raise("Type should be bool value");
        SWIG_fail;
    }
    $1 = (boolVal == true) ? GS_TRUE : GS_FALSE;
}

/*
 * Correct PartitionController.getContainerNames() function
 */
%extend griddb::PartitionController {
    void get_container_names(int32_t partition_index, int64_t start, int64_t limit = -1,
            const GSChar * const ** stringList = NULL, size_t *size = NULL){
        return $self->get_container_names(partition_index, start, stringList, size, limit);
    }
}

//Correct check for input integer: should check range and type
%fragment("convertObjectToInt", "header", fragment = "SWIG_AsVal_bool", fragment = "SWIG_AsVal_int") {
static bool convertObjectToInt(v8::Local<v8::Value> value, int* intValPtr) {
    if (!intValPtr) {
        return false;
    }
    if (!value->IsInt32()) {
        return false;
    }
    *intValPtr = value->IntegerValue();
    return true;
}
}

%typemap(in, fragment = "convertObjectToInt") (int) {
    v8::Local<v8::Value> obj = $input;
    bool checkConvert = convertObjectToInt(obj, &$1);
    if (!checkConvert) {
        SWIG_V8_Raise("Type should be integer value");
        SWIG_fail;
    }
}

//Correct check for input size_t: should be integer, not float
%fragment("convertObjectToSizeT", "header", fragment = "SWIG_AsVal_size_t") {
static bool convertObjectToSizeT(v8::Local<v8::Value> value, size_t* intValPtr) {
    if (!intValPtr) {
        return false;
    }
    int checkConvert = SWIG_AsVal_size_t(value, intValPtr);
    if (!SWIG_IsOK(checkConvert)) {
        return false;
    }
    if (value->NumberValue() != *intValPtr) {
        return false;
    }
    return true;
}
}

%typemap(in, fragment = "convertObjectToSizeT") (size_t) {
    v8::Local<v8::Value> obj = $input;

    bool vbool = convertObjectToSizeT(obj, &$1);
    if (!vbool) {
        SWIG_V8_Raise("Type should be unsigned integer value");
        SWIG_fail;
    }
}

