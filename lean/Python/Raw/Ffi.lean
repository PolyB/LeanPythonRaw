namespace Python.Raw.Ffi

-- This file contains raw bindings to C functions

private opaque PyObjectNonempty : NonemptyType
def PyObject : Type := PyObjectNonempty.type

structure PyError where
 exType : PyObject
 exValue : Option PyObject
 exTraceback : Option PyObject

abbrev IOExp (t : Type) := IO $ Except PyError t

@[extern "Lean_Py_Initialize"]
opaque Py_Initialize : IO Unit

@[extern "Lean_Py_IsInitialized"]
opaque Py_IsInitialized : IO Bool

@[extern "Lean_Py_FinalizeEx"]
opaque Py_FinalizeEx : IO Bool

@[extern "Lean_PyUnicode_FromString"]
opaque PyUnicode_FromString : String → IO PyObject

@[extern "Lean_PyObject_GetAttrString"]
opaque PyObject_GetAttrString : PyObject → String → IOExp PyObject

@[extern "Lean_PyObject_GetAttr"]
opaque PyObject_GetAttr : PyObject → PyObject → IOExp PyObject

@[extern "Lean_PyUnicode_AsUTF8"]
opaque PyUnicode_AsUTF8 : PyObject → IOExp String

@[extern "Lean_PyImport_Import"]
opaque PyImport_Import : PyObject → IOExp PyObject

@[extern "Lean_MakeTuple"]
opaque PyTuple_Make : Array PyObject → IOExp PyObject

@[extern "Lean_MakeList"]
opaque PyList_Make : Array PyObject → IOExp PyObject

@[extern "Lean_PyDict_New"]
opaque PyDict_New : IOExp PyObject

@[extern "Lean_PyDict_SetItemString"]
opaque PyDict_SetItemString : (dict : PyObject) → (key : String) → (value : PyObject) → IOExp PUnit

@[extern "Lean_PyDict_SetItem"]
opaque PyDict_SetItem: (dict : PyObject) → (key : PyObject) → (value : PyObject) → IOExp PUnit

@[extern "Lean_PyObject_Call"]
opaque PyObject_Call : (callable : PyObject) → (args_tuple : PyObject) → (kwargs_dict : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_Call_NoKw"]
opaque PyObject_Call_NoKw : (callable : PyObject) → (args_tuple : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_CallNoArgs"]
opaque PyObject_CallNoArgs : (callable : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_CallOneArg"]
opaque PyObject_CallOneArg : (callable : PyObject) → (arg : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_CallMethodOneArg"]
opaque PyObject_CallMethodOneArg : (obj : PyObject) → (name : PyObject) → (arg : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_Print"]
opaque PyObject_Print : PyObject → IO PUnit

@[extern "Lean_PyObject_Str"]
opaque PyObject_Str : PyObject → IOExp PyObject

@[extern "Lean_PyObject_Repr"]
opaque PyObject_Repr : PyObject → IOExp PyObject

@[extern "Lean_PyLong_FromLeanInt"]
opaque PyLong_FromLeanInt : Int → IOExp PyObject

@[extern "Lean_PyLong_ToLeanInt"]
opaque PyLong_ToLeanInt : PyObject → IOExp Int

-- please make it start with `Lean` so that it can be pretty_printed by python
def PyCapsule_Key : Type := String

opaque PyCapsule_Get_Value : PyCapsule_Key → Type

@[extern "Lean_PyCapsule_Make"]
opaque PyCapsule_Make : (k : PyCapsule_Key) → PyCapsule_Get_Value k → IOExp PyObject

@[extern "Lean_PyCapsule_Get"]
opaque PyCapsule_Get : (k : PyCapsule_Key) → PyObject → IOExp (PyCapsule_Get_Value k)

-- Py_None is done manually as it is used to define `Inhabited PyObject`

@[extern "Lean_PyObject_Py_None"]
private opaque mkPyNone : Unit → PyObject := fun _ => Classical.choice PyObjectNonempty.property
def Py_None : PyObject := mkPyNone ()

instance : Inhabited PyObject where
  default := Py_None

macro "mkpycheck!" name:ident : command => do
  let u : Lean.TSyntax `str := Lean.quote s!"Lean_{name}"
  return Lean.mkNullNode #[
    ← `(opaque $name : PyObject → Bool),
    -- ← `(attribute [extern $(Lean.quote s!"Lean_{name}")] $name)
    ← `(attribute [extern $(Lean.TSyntax.mk u.raw)] $name)
  ]

mkpycheck! PyBool_Check
mkpycheck! PyUnicode_Check
mkpycheck! PyList_Check
mkpycheck! PyTuple_Check
mkpycheck! PyDict_Check


macro "mkpyobj!" name:ident : command =>do
                                          let extern_ident := Lean.mkIdentFrom name (Lean.Name.mkSimple s!"{name.getId.toString}_")
                                          let definition ← `(private opaque $extern_ident (u : Unit): PyObject)
                                          let strLit : Lean.TSyntax `str := Lean.quote s!"Lean_PyObject_{name}"
                                          let attrdef ← `(attribute [extern $(Lean.TSyntax.mk strLit.raw)] $extern_ident)
                                          let defpub ← `(def $name : PyObject := $extern_ident ())
                                          return Lean.mkNullNode #[definition, attrdef, defpub]
                                         
syntax "mkpyobjs!" ident+ : command
macro_rules
  | `(mkpyobjs! $[$n:ident]*) => do
      return Lean.mkNullNode $ ← n.mapM (λ i => `(mkpyobj! $i))

mkpyobjs!
  -- Fundamental objects
  -- Py_None should be here, but it's manually defined to implement `Inhabited PyObject
  Py_False
  Py_True
  -- exceptions
  PyExc_BaseException
  PyExc_Exception
  PyExc_StopAsyncIteration
  PyExc_StopIteration
  PyExc_GeneratorExit
  PyExc_ArithmeticError
  PyExc_LookupError
  PyExc_AssertionError
  PyExc_AttributeError
  PyExc_BufferError
  PyExc_EOFError
  PyExc_FloatingPointError
  PyExc_OSError
  PyExc_ImportError
  PyExc_ModuleNotFoundError
  PyExc_IndexError
  PyExc_KeyError
  PyExc_KeyboardInterrupt
  PyExc_MemoryError
  PyExc_NameError
  PyExc_OverflowError
  PyExc_RuntimeError
  PyExc_RecursionError
  PyExc_NotImplementedError
  PyExc_SyntaxError
  PyExc_IndentationError
  PyExc_TabError
  PyExc_ReferenceError
  PyExc_SystemError
  PyExc_SystemExit
  PyExc_TypeError
  PyExc_UnboundLocalError
  PyExc_UnicodeError
  PyExc_UnicodeEncodeError
  PyExc_UnicodeDecodeError
  PyExc_UnicodeTranslateError
  PyExc_ValueError
  PyExc_ZeroDivisionError
  PyExc_BlockingIOError
  PyExc_BrokenPipeError
  PyExc_ChildProcessError
  PyExc_ConnectionError
  PyExc_ConnectionAbortedError
  PyExc_ConnectionRefusedError
  PyExc_ConnectionResetError
  PyExc_FileExistsError
  PyExc_FileNotFoundError
  PyExc_InterruptedError
  PyExc_IsADirectoryError
  PyExc_NotADirectoryError
  PyExc_PermissionError
  PyExc_ProcessLookupError
  PyExc_TimeoutError