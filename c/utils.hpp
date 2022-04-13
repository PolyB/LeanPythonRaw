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

static inline lean_obj_res lean_mk_option_some(lean_obj_arg obj)
{
    lean_object *tuple = lean_alloc_ctor(1, 1, 0);
    lean_ctor_set(tuple, 0, obj);
    return tuple;
}

static inline lean_obj_res lean_mk_option_none()
{
    return lean_box(0);
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
    PyObject *exType = NULL;
    PyObject *exValue = NULL;
    PyObject *exTraceBack = NULL;

    PyErr_Fetch(&exType, &exValue, &exTraceBack);
    if (!exType)
    {
        // maybe it cost a little more, but it's convenient and shouldn't happen a lot
        PyErr_SetString(PyExc_Exception, "Lean ffi : got empty exception");
        PyErr_Fetch(&exType, &exValue, &exTraceBack);
        assert(exType);
    }
    PyGILState_Release(state);

    lean_obj_res exTypeL, exValueL, exTraceBackL;

    exTypeL = make_pyobject(exType);

    if (exValue)
        exValueL = lean_mk_option_some(make_pyobject(exValue));
    else
        exValueL = lean_mk_option_none();

    if (exTraceBack)
        exTraceBackL = lean_mk_option_some(make_pyobject(exTraceBack));
    else
        exTraceBackL = lean_mk_option_none();

    lean_object *pyError = lean_alloc_ctor(0, 3, 0);
    lean_ctor_set(pyError, 0, exTypeL);
    lean_ctor_set(pyError, 1, exValueL);
    lean_ctor_set(pyError, 2, exTraceBackL);

    // Make a IO (Except.err PyError)

    lean_object *tuple = lean_alloc_ctor(0, 1, 0);
    lean_ctor_set(tuple, 0, pyError);
    return lean_io_result_mk_ok(tuple);
}