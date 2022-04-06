#include <lean/lean.h>
#include <Python.h>
#include <optional>

// PYOBJECT DEF
static void Lean_pyobject_finalizer(void *ptr) {
    PyObject *obj = (PyObject *)ptr;
    Py_DecRef(obj);
}
// not clear what it is supposed to do
static void Lean_pyobject_foreach(void *mod, b_lean_obj_arg fn) {}

// not pretty
static lean_external_class * get_pyobject_class() {
    static lean_external_class* c =
        lean_register_external_class(&Lean_pyobject_finalizer, &Lean_pyobject_foreach);
    return c;
}

// converts PyObject to and from an opaque lean type
inline PyObject *get_pyobject(lean_obj_arg obj) {
    return (PyObject *)lean_get_external_data(obj);
}

inline lean_obj_res make_pyobject(PyObject *obj) {
    return (lean_obj_res)lean_alloc_external(get_pyobject_class(), obj);
}

// IO Except wrapper

template <class F>
inline lean_obj_res WrapIOExcept(F&& f) {
    PyGILState_STATE state = PyGILState_Ensure();

    std::optional<lean_obj_res> result = f();

    if (result.has_value())
    {
        PyGILState_Release(state);

        // Make a IO (Except.ok x)
        lean_object *tuple = lean_alloc_ctor(1, 1, 0);
        lean_ctor_set(tuple, 0, *result);
        return lean_io_result_mk_ok(tuple);
    }

    PyObject *error = PyErr_Occurred();
    if (!error)
    {
        // maybe it cost a little more, but it's convenient and shouldn't happen a lot
        PyErr_SetString(PyExc_Exception, "Lean ffi : got empty exception");
        error = PyErr_Occurred();
    }
    PyGILState_Release(state);

    lean_obj_res error_lean = make_pyobject(error);

    // Make a IO (Except.err x)

    lean_object *tuple = lean_alloc_ctor(0, 1, 0);
    lean_ctor_set(tuple, 0, error_lean);
    return lean_io_result_mk_ok(tuple);
}