namespace Python.Raw.Ffi

private constant PyObjectNonempty : NonemptyType
def PyObject : Type := PyObjectNonempty.type

abbrev IOExp (t : Type) := IO $ Except PyObject t

@[extern "Lean_Py_Initialize"]
constant Py_Initialize : IO Unit

@[extern "Lean_Py_IsInitialized"]
constant Py_IsInitialized : IO Bool

@[extern "Lean_Py_FinalizeEx"]
constant Py_FinalizeEx : IO Bool

@[extern "Lean_PyUnicode_FromString"]
constant PyUnicode_FromString : String → IO PyObject

@[extern "Lean_PyObject_GetAttrString"]
constant PyObject_GetAttrString : PyObject → String → IOExp PyObject

@[extern "Lean_PyUnicode_AsUTF8"]
constant PyUnicode_AsUTF8 : PyObject → IOExp String

@[extern "Lean_PyImport_Import"]
constant PyImport_Import : PyObject → IOExp PyObject

@[extern "Lean_MakeTuple"]
constant PyTuple_Make : Array PyObject → IOExp PyObject

@[extern "Lean_MakeList"]
constant PyList_Make : Array PyObject → IOExp PyObject

@[extern "Lean_PyDict_New"]
constant PyDict_New : IOExp PyObject

@[extern "Lean_PyDict_SetItemString"]
constant PyDict_SetItemString : (dict : PyObject) → (key : String) → (value : PyObject) → IOExp PUnit

@[extern "Lean_PyObject_Call"]
constant PyObject_Call : (callable : PyObject) → (args_tuple : PyObject) → (kwargs_dict : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_CallNoArgs"]
constant PyObject_CallNoArgs : (callable : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_CallOneArg"]
constant PyObject_CallOneArg : (callable : PyObject) → (arg : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_Print"]
constant PyObject_Print : PyObject → IO PUnit