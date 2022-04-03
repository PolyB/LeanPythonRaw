#include <Python.h>
#include <lean/lean.h>
#include <optional>
#include <stdio.h>

#include "utils.hpp"

extern "C" lean_obj_res Lean_Py_Initialize() {
    Py_Initialize();
    return lean_io_result_mk_ok(lean_box(0)); // IO PUnit
}

extern "C" lean_obj_res Lean_Py_FinalizeEx() {
    if (Py_FinalizeEx())
        return lean_io_result_mk_ok(lean_box(1)); // IO True
    else
        return lean_io_result_mk_ok(lean_box(0)); // IO False
}

extern "C" lean_obj_res Lean_Py_IsInitialized() {
    if (Py_IsInitialized())
        return lean_io_result_mk_ok(lean_box(1)); // IO True
    else
        return lean_io_result_mk_ok(lean_box(0)); // IO False
}

extern "C" lean_obj_res Lean_PyUnicode_FromString(lean_obj_arg s) {
    const char *s_cstr = lean_string_cstr(s);
    PyObject *obj = PyUnicode_FromString(s_cstr);
    return lean_io_result_mk_ok(make_pyobject(obj));
}

extern "C" lean_obj_res Lean_PyObject_GetAttrString(lean_obj_arg obj, lean_obj_arg s) {
    PyObject *py_obj = get_pyobject(obj);
    const char *s_cstr = lean_string_cstr(s);
    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyObject_GetAttrString(py_obj, s_cstr);
        if (res == nullptr)
            return {};
        return {make_pyobject(res)};
    });
}

extern "C" lean_obj_res Lean_PyUnicode_AsUTF8(lean_obj_arg obj) {
    PyObject *py_obj = get_pyobject(obj);

    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        const char *obj_cstr = PyUnicode_AsUTF8(py_obj);
        if (obj_cstr == nullptr)
            return {};
        return lean_mk_string(obj_cstr);
    });
}

extern "C" lean_obj_res Lean_PyImport_Import(lean_obj_arg obj) {
    PyObject *py_obj = get_pyobject(obj);
    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyImport_Import(py_obj);
        if (res == nullptr)
            return {};
        return make_pyobject(res);
    });
}

extern "C" lean_obj_res Lean_MakeTuple(lean_obj_arg obj) {
    size_t obj_count = lean_array_size(obj);
    lean_object **objs_cptr = lean_array_cptr(obj);

    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyTuple_New(obj_count);
        if (res == nullptr)
            return {};

        for (Py_ssize_t i = 0; i < obj_count; i++)
        {
            PyObject *py_obj = (PyObject *)lean_get_external_data(objs_cptr[i]);
            PyTuple_SET_ITEM(res, i, py_obj);
        }

        return make_pyobject(res);
    });
}

extern "C" lean_obj_res Lean_MakeList(lean_obj_arg obj) {
    size_t obj_count = lean_array_size(obj);
    lean_object **objs_cptr = lean_array_cptr(obj);

    // TODO : error handling
    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyList_New(obj_count);
        if (res == nullptr)
            return {};

        for (Py_ssize_t i = 0; i < obj_count; i++)
        {
            PyObject *py_obj = (PyObject *)lean_get_external_data(objs_cptr[i]);
            PyList_SET_ITEM(res, i, py_obj);
        }
        return make_pyobject(res);
    });
}

extern "C" lean_obj_res Lean_PyDict_New() {
    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *pyobj = PyDict_New();
        if (pyobj == nullptr)
            return {};
        return make_pyobject(pyobj);
    });
}

extern "C" lean_obj_res Lean_PyDict_SetItemString(lean_obj_arg dict, lean_obj_arg key, lean_obj_arg val) {
    PyObject *py_dict = get_pyobject(dict);
    const char *key_cstr = lean_string_cstr(key);
    PyObject *py_val = get_pyobject(val);

    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        int call_res = PyDict_SetItemString(py_dict, key_cstr, py_val);
        if (call_res == -1)
            return {};
        
        return {lean_box(0)}; // Unit
    });
}

extern "C" lean_obj_res Lean_PyObject_Call(lean_obj_arg callable, lean_obj_arg args, lean_obj_arg kwargs) {
    PyObject *py_callable = get_pyobject(callable);
    PyObject *py_args = get_pyobject(args);
    PyObject *py_kwargs = get_pyobject(kwargs);

    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyObject_Call(py_callable, py_args, py_kwargs);
        if (res == nullptr)
            return {};
        return make_pyobject(res);
    });
}

extern "C" lean_obj_res Lean_PyObject_CallNoArgs(lean_obj_arg callable) {
    PyObject *py_callable = get_pyobject(callable);

    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyObject_CallNoArgs(py_callable);
        if (res == nullptr)
            return {};
        return make_pyobject(res);
    });
}

extern "C" lean_obj_res Lean_PyObject_CallOneArg(lean_obj_arg callable, lean_obj_arg arg) {
    PyObject *py_callable = get_pyobject(callable);
    PyObject *py_arg = get_pyobject(arg);

    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyObject_CallOneArg(py_callable, py_arg);
        if (res == nullptr)
            return {};
        return make_pyobject(res);
    });
}

extern "C" lean_obj_res Lean_PyObject_Print(lean_obj_arg arg) {
    PyObject *py_obj = (PyObject *)lean_get_external_data(arg);
    FILE* out = stdout;
    PyObject_Print(py_obj, out, 0);
    return lean_io_result_mk_ok(lean_box(0));
}