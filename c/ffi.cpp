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

extern "C" lean_obj_res Lean_PyObject_GetAttr(lean_obj_arg obj, lean_obj_arg key) {
    PyObject *py_obj = get_pyobject(obj);
    PyObject *py_key = get_pyobject(key);
    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyObject_GetAttr(py_obj, py_key);
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

extern "C" lean_obj_res Lean_PyDict_SetItem(lean_obj_arg dict, lean_obj_arg key, lean_obj_arg val) {
    PyObject *py_dict = get_pyobject(dict);
    PyObject *py_key = get_pyobject(key);
    PyObject *py_val = get_pyobject(val);

    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        int call_res = PyDict_SetItem(py_dict, py_key, py_val);
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

extern "C" lean_obj_res Lean_PyObject_Call_NoKw(lean_obj_arg callable, lean_obj_arg args) {
    PyObject *py_callable = get_pyobject(callable);
    PyObject *py_args = get_pyobject(args);

    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyObject_Call(py_callable, py_args, NULL);
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

extern "C" lean_obj_res Lean_PyBool_Mk(lean_obj_arg arg) {
    PyObject *res_py;
    if (arg == (void*)0x1)
        res_py = Py_True;
    else
        res_py = Py_False;
    Py_IncRef(res_py);
    return lean_io_result_mk_ok(make_pyobject(res_py));
}

extern "C" lean_obj_res Lean_PyObject_Repr(lean_obj_arg arg) {
    PyObject *argP = get_pyobject(arg);
    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyObject_Repr(argP);
        if (res == nullptr)
            return {};
        return make_pyobject(res);
    });
}

extern "C" lean_obj_res Lean_PyObject_Str(lean_obj_arg arg) {
    PyObject *argP = get_pyobject(arg);
    return WrapIOExcept([=]() -> std::optional<lean_obj_res> {
        PyObject *res = PyObject_Str(argP);
        if (res == nullptr)
            return {};
        return make_pyobject(res);
    });
}

#define MakePyObjectRefSymbol(Name)                                     \
    extern "C" lean_obj_res Lean_PyObject_##Name(lean_obj_arg arg) {    \
        (void)arg;                                                      \
        Py_IncRef(Name);                                                \
        return make_pyobject(Name);                                     \
    }
// Fundamental objects
MakePyObjectRefSymbol(Py_None)
MakePyObjectRefSymbol(Py_True)
MakePyObjectRefSymbol(Py_False)
// Exceptions
MakePyObjectRefSymbol(PyExc_BaseException)
MakePyObjectRefSymbol(PyExc_Exception)
MakePyObjectRefSymbol(PyExc_StopAsyncIteration)
MakePyObjectRefSymbol(PyExc_StopIteration)
MakePyObjectRefSymbol(PyExc_GeneratorExit)
MakePyObjectRefSymbol(PyExc_ArithmeticError)
MakePyObjectRefSymbol(PyExc_LookupError)
MakePyObjectRefSymbol(PyExc_AssertionError)
MakePyObjectRefSymbol(PyExc_AttributeError)
MakePyObjectRefSymbol(PyExc_BufferError)
MakePyObjectRefSymbol(PyExc_EOFError)
MakePyObjectRefSymbol(PyExc_FloatingPointError)
MakePyObjectRefSymbol(PyExc_OSError)
MakePyObjectRefSymbol(PyExc_ImportError)
MakePyObjectRefSymbol(PyExc_ModuleNotFoundError)
MakePyObjectRefSymbol(PyExc_IndexError)
MakePyObjectRefSymbol(PyExc_KeyError)
MakePyObjectRefSymbol(PyExc_KeyboardInterrupt)
MakePyObjectRefSymbol(PyExc_MemoryError)
MakePyObjectRefSymbol(PyExc_NameError)
MakePyObjectRefSymbol(PyExc_OverflowError)
MakePyObjectRefSymbol(PyExc_RuntimeError)
MakePyObjectRefSymbol(PyExc_RecursionError)
MakePyObjectRefSymbol(PyExc_NotImplementedError)
MakePyObjectRefSymbol(PyExc_SyntaxError)
MakePyObjectRefSymbol(PyExc_IndentationError)
MakePyObjectRefSymbol(PyExc_TabError)
MakePyObjectRefSymbol(PyExc_ReferenceError)
MakePyObjectRefSymbol(PyExc_SystemError)
MakePyObjectRefSymbol(PyExc_SystemExit)
MakePyObjectRefSymbol(PyExc_TypeError)
MakePyObjectRefSymbol(PyExc_UnboundLocalError)
MakePyObjectRefSymbol(PyExc_UnicodeError)
MakePyObjectRefSymbol(PyExc_UnicodeEncodeError)
MakePyObjectRefSymbol(PyExc_UnicodeDecodeError)
MakePyObjectRefSymbol(PyExc_UnicodeTranslateError)
MakePyObjectRefSymbol(PyExc_ValueError)
MakePyObjectRefSymbol(PyExc_ZeroDivisionError)
MakePyObjectRefSymbol(PyExc_BlockingIOError)
MakePyObjectRefSymbol(PyExc_BrokenPipeError)
MakePyObjectRefSymbol(PyExc_ChildProcessError)
MakePyObjectRefSymbol(PyExc_ConnectionError)
MakePyObjectRefSymbol(PyExc_ConnectionAbortedError)
MakePyObjectRefSymbol(PyExc_ConnectionRefusedError)
MakePyObjectRefSymbol(PyExc_ConnectionResetError)
MakePyObjectRefSymbol(PyExc_FileExistsError)
MakePyObjectRefSymbol(PyExc_FileNotFoundError)
MakePyObjectRefSymbol(PyExc_InterruptedError)
MakePyObjectRefSymbol(PyExc_IsADirectoryError)
MakePyObjectRefSymbol(PyExc_NotADirectoryError)
MakePyObjectRefSymbol(PyExc_PermissionError)
MakePyObjectRefSymbol(PyExc_ProcessLookupError)
MakePyObjectRefSymbol(PyExc_TimeoutError)